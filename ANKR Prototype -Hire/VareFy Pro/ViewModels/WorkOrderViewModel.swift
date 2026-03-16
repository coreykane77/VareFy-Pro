import Foundation
import UIKit
import Observation

@Observable
class WorkOrderViewModel {

    var workOrders: [WorkOrder] = PreviewData.workOrders
    var isOnline: Bool = false
    var isInsideRadius: Bool = true
    var radiusCountdownSeconds: Int = 0
    var unreadChatOrderIds: Set<UUID> = []
    var currentChatOrderId: UUID? = nil

    var hasUnreadChats: Bool { !unreadChatOrderIds.isEmpty }

    private var billingTask: Task<Void, Never>?
    private var radiusTask: Task<Void, Never>?

    // Wall-clock billing state (lives in memory + UserDefaults for persistence)
    private var billingWallClockStart: Date? = nil
    private var billingBaseSeconds: Double = 0

    // MARK: - UserDefaults keys
    private enum UDKey {
        static let orderId      = "vfy_billing_order_id"
        static let wallStart    = "vfy_billing_wall_start"   // TimeInterval
        static let accumulated  = "vfy_billing_accumulated"  // Double seconds
    }

    init() {
        restoreBillingStateIfNeeded()
    }

    func markChatRead(for id: UUID) {
        unreadChatOrderIds.remove(id)
    }

    func markChatUnread(for id: UUID) {
        unreadChatOrderIds.insert(id)
    }

    // MARK: - Helpers

    func index(of id: UUID) -> Int? {
        workOrders.firstIndex { $0.id == id }
    }

    func order(id: UUID) -> WorkOrder? {
        workOrders.first { $0.id == id }
    }

    /// The ID of any order currently in an active work state (billing, paused, or post-work).
    var activeOrderId: UUID? {
        workOrders.first {
            $0.status == .activeBilling || $0.status == .paused || $0.status == .postWork
        }?.id
    }

    // MARK: - Confirmation

    func confirmJob(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .pending else { return }
        workOrders[i].addTimelineEvent(.confirmed)
        workOrders[i].status = .readyToNavigate
    }

    // MARK: - Drive

    func startDrive(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .readyToNavigate else { return }
        workOrders[i].status = .enRoute
        isOnline = true
    }

    func simulateArrival(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .enRoute else { return }
        workOrders[i].addTimelineEvent(.arrived)
        workOrders[i].status = .arrived
        workOrders[i].status = .preWork
    }

    // MARK: - Pre Work

    func expandRadius(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .preWork,
              !workOrders[i].radiusExpanded else { return }
        workOrders[i].radiusExpanded = true
        workOrders[i].addTimelineEvent(.radiusExpanded)
    }

    func addPrePhoto(_ photo: UIImage, for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].prePhotos.count < Constants.maxPhotosPerGate else { return }
        workOrders[i].prePhotos.append(photo)
    }

    func removePrePhoto(at photoIndex: Int, for id: UUID) {
        guard let i = index(of: id),
              photoIndex < workOrders[i].prePhotos.count else { return }
        workOrders[i].prePhotos.remove(at: photoIndex)
    }

    func canStartWork(for id: UUID) -> Bool {
        guard let order = order(id: id) else { return false }
        return order.prePhotoCount >= Constants.minPhotosRequired
    }

    // MARK: - Billing

    func startWork(for id: UUID, walletVM: WalletViewModel) {
        guard let i = index(of: id),
              canStartWork(for: id),
              workOrders[i].status == .preWork else { return }
        workOrders[i].billingStartTime = Date()
        workOrders[i].addTimelineEvent(.started)
        workOrders[i].status = .activeBilling
        startBillingTimer(for: id)
    }

    func pauseWork(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .activeBilling || workOrders[i].status == .preWork else { return }
        workOrders[i].pausedReturnStatus = workOrders[i].status
        workOrders[i].addTimelineEvent(.paused)
        workOrders[i].status = .paused
        stopBillingTimer(clearPersistence: true)
        cancelRadiusCountdown()
    }

    func autoPause(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .activeBilling else { return }
        workOrders[i].pausedReturnStatus = .activeBilling
        workOrders[i].addTimelineEvent(.autoPause)
        workOrders[i].status = .paused
        stopBillingTimer(clearPersistence: true)
        cancelRadiusCountdown()
    }

    func resumeWork(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .paused else { return }
        let returnTo = workOrders[i].pausedReturnStatus ?? .activeBilling
        workOrders[i].addTimelineEvent(.resumed)
        workOrders[i].status = returnTo
        workOrders[i].pausedReturnStatus = nil
        if returnTo == .activeBilling {
            startBillingTimer(for: id)
        }
    }

    // MARK: - Post Work

    func moveToPostWork(for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].status == .activeBilling else { return }
        stopBillingTimer(clearPersistence: true)
        cancelRadiusCountdown()
        workOrders[i].status = .postWork
    }

    func addPostPhoto(_ photo: UIImage, for id: UUID) {
        guard let i = index(of: id),
              workOrders[i].postPhotos.count < Constants.maxPhotosPerGate else { return }
        workOrders[i].postPhotos.append(photo)
    }

    func removePostPhoto(at photoIndex: Int, for id: UUID) {
        guard let i = index(of: id),
              photoIndex < workOrders[i].postPhotos.count else { return }
        workOrders[i].postPhotos.remove(at: photoIndex)
    }

    func canComplete(for id: UUID) -> Bool {
        guard let order = order(id: id) else { return false }
        return order.postPhotoCount >= Constants.minPhotosRequired
    }

    func completeWork(for id: UUID, walletVM: WalletViewModel) {
        guard let i = index(of: id),
              canComplete(for: id),
              workOrders[i].status == .postWork else { return }
        workOrders[i].addTimelineEvent(.completed)
        workOrders[i].status = .clientReview
        walletVM.creditBalance(workOrders[i].totalPaid, description: workOrders[i].serviceTitle)
    }

    // MARK: - Radius

    func setInsideRadius() {
        isInsideRadius = true
        cancelRadiusCountdown()
    }

    func setOutsideRadius(for id: UUID) {
        isInsideRadius = false
        guard let order = order(id: id), order.status == .activeBilling else { return }
        startRadiusCountdown(for: id)
    }

    // MARK: - Billing Timer (wall-clock based for persistence)

    private func startBillingTimer(for id: UUID) {
        stopBillingTimer(clearPersistence: false)
        guard let i = index(of: id) else { return }

        // Base = whatever elapsed time we already have (from restored or prior sessions)
        billingBaseSeconds = workOrders[i].elapsedBillingSeconds
        billingWallClockStart = Date()

        // Persist so we can restore on app relaunch
        UserDefaults.standard.set(id.uuidString, forKey: UDKey.orderId)
        UserDefaults.standard.set(Date().timeIntervalSinceReferenceDate, forKey: UDKey.wallStart)
        UserDefaults.standard.set(billingBaseSeconds, forKey: UDKey.accumulated)

        billingTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                if let j = index(of: id),
                   workOrders[j].status == .activeBilling,
                   let start = billingWallClockStart {
                    workOrders[j].elapsedBillingSeconds = billingBaseSeconds + Date().timeIntervalSince(start)
                }
            }
        }
    }

    private func stopBillingTimer(clearPersistence: Bool) {
        billingTask?.cancel()
        billingTask = nil
        billingWallClockStart = nil
        if clearPersistence {
            UserDefaults.standard.removeObject(forKey: UDKey.orderId)
            UserDefaults.standard.removeObject(forKey: UDKey.wallStart)
            UserDefaults.standard.removeObject(forKey: UDKey.accumulated)
        }
    }

    /// On cold launch, check if billing was active and restore elapsed time + restart timer.
    private func restoreBillingStateIfNeeded() {
        let ud = UserDefaults.standard
        guard
            let idString = ud.string(forKey: UDKey.orderId),
            let id = UUID(uuidString: idString),
            let idx = workOrders.firstIndex(where: { $0.id == id })
        else { return }

        let accumulated = ud.double(forKey: UDKey.accumulated)
        let wallStartEpoch = ud.double(forKey: UDKey.wallStart)
        guard wallStartEpoch > 0 else { return } // was paused, don't restore active billing

        let wallStart = Date(timeIntervalSinceReferenceDate: wallStartEpoch)
        let elapsed = accumulated + Date().timeIntervalSince(wallStart)

        workOrders[idx].elapsedBillingSeconds = elapsed
        workOrders[idx].status = .activeBilling
        startBillingTimer(for: id)
    }

    // MARK: - Radius Countdown

    private func startRadiusCountdown(for id: UUID) {
        cancelRadiusCountdown()
        radiusCountdownSeconds = Constants.radiusCountdownSeconds
        radiusTask = Task { @MainActor in
            while radiusCountdownSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                radiusCountdownSeconds -= 1
            }
            if !Task.isCancelled && !isInsideRadius {
                autoPause(for: id)
            }
        }
    }

    private func cancelRadiusCountdown() {
        radiusTask?.cancel()
        radiusTask = nil
        radiusCountdownSeconds = 0
    }
}
