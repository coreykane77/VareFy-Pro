import Foundation
import UIKit
import Observation
import Supabase

// Matches public.work_orders columns exactly for Supabase decoding.
// Dates decoded as String because functions.invoke uses a plain JSONDecoder
// (no custom dateDecodingStrategy), while .execute().value uses the SDK's ISO 8601 decoder.
// Keeping both fields as String makes decoding work identically across both call paths.
private struct SupabaseWorkOrder: Decodable {
    let id: UUID
    let client_id: UUID
    let pro_id: UUID?
    let status: WorkOrderStatus
    let service_title: String
    let address: String
    let latitude: Double?
    let longitude: Double?
    let hourly_rate: Double
    let client_notes: String?
    let scheduled_at: String
    let radius_expanded: Bool
    let paused_return_status: WorkOrderStatus?
    let response_deadline: String?
    let completed_at: String?
    let billing_start_at: String?
    let elapsed_billing_seconds: Double
    let labor_total: Double
    let materials_total: Double
    let total_paid: Double
    let payout_status: String

    func toWorkOrder(clientName: String = "Client") -> WorkOrder {
        WorkOrder(
            id: id,
            clientId: client_id,
            clientName: clientName,
            clientInitials: String(clientName.prefix(2)).uppercased(),
            serviceTitle: service_title,
            address: address,
            scheduledTime: Self.parseDate(scheduled_at) ?? Date(),
            status: status,
            clientNotes: client_notes ?? "",
            serviceId: "",
            hourlyRate: hourly_rate,
            materialItems: [],
            timelineEvents: [],
            prePhotoRecords: [],
            postPhotoRecords: [],
            billingStartTime: Self.parseDate(billing_start_at),
            elapsedBillingSeconds: elapsed_billing_seconds,
            radiusExpanded: radius_expanded,
            pausedReturnStatus: paused_return_status,
            responseDeadline: Self.parseDate(response_deadline),
            completedAt: Self.parseDate(completed_at)
        )
    }

    private static let isoFull: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let isoBasic = ISO8601DateFormatter()

    private static func parseDate(_ s: String?) -> Date? {
        guard let s else { return nil }
        return isoFull.date(from: s) ?? isoBasic.date(from: s)
    }
}

private struct SupabaseEstimate: Decodable {
    let id: UUID
    let work_order_id: UUID
    let title: String?
    let description: String?
    let valid_for_days: Int?
    let estimated_hours: Double
    let estimated_materials: Double
    let estimated_total: Double
    let proposed_start_date: String
    let status: String
    let created_at: String?

    func toEstimate() -> Estimate {
        let isoFull: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        let isoBasic = ISO8601DateFormatter()
        func parse(_ s: String?) -> Date? {
            guard let s else { return nil }
            return isoFull.date(from: s) ?? isoBasic.date(from: s)
        }
        return Estimate(
            id: id,
            workOrderId: work_order_id,
            title: title,
            description: description,
            validForDays: valid_for_days ?? 30,
            estimatedHours: estimated_hours,
            estimatedMaterials: estimated_materials,
            estimatedTotal: estimated_total,
            proposedStartDate: parse(proposed_start_date) ?? Date(),
            status: EstimateStatus(rawValue: status) ?? .pending,
            createdAt: parse(created_at)
        )
    }
}

// Decoded response from the transition-work-order Edge Function
private struct TransitionResponse: Decodable {
    let success: Bool?
    let error: String?
    let order: SupabaseWorkOrder?
}

@Observable
class WorkOrderViewModel {

    var workOrders: [WorkOrder] = []
    var isLoading: Bool = false
    var isOnline: Bool = false
    var isInsideRadius: Bool = true
    var radiusCountdownSeconds: Int = 0
    var unreadChatOrderIds: Set<UUID> = []
    var currentChatOrderId: UUID? = nil
    var sentEstimateOrderIds: Set<UUID> = []
    var proEstimates: [UUID: [Estimate]] = [:]
    var photoUploadError: String? = nil

    var hasUnreadChats: Bool { !unreadChatOrderIds.isEmpty }

    private(set) var currentProId: UUID? = nil
    private var billingTask: Task<Void, Never>?
    private var radiusTask: Task<Void, Never>?
    private var realtimeChannel: RealtimeChannelV2?

    // Wall-clock billing anchors (server timestamp drives accuracy)
    private var billingWallClockStart: Date? = nil
    private var billingBaseSeconds: Double = 0
    private var clientProfiles: [UUID: String] = [:]

    // MARK: - Supabase Fetch

    func fetchWorkOrders(proId: UUID) async {
        currentProId = proId
        isLoading = true
        do {
            let rows: [SupabaseWorkOrder] = try await supabase
                .from("work_orders")
                .select()
                .eq("pro_id", value: proId)
                .order("scheduled_at")
                .execute()
                .value

            let clientIds = Array(Set(rows.map { $0.client_id }))
            await fetchClientProfiles(clientIds: clientIds)

            // Preserve in-flight photo records and local material items across realtime refreshes.
            // toWorkOrder() initialises these as empty; without this, a realtime update wipes
            // any photos the pro just uploaded before the gate check runs.
            let existing = workOrders
            workOrders = rows.map { row in
                var order = row.toWorkOrder(clientName: clientProfiles[row.client_id] ?? "Client")
                if let prev = existing.first(where: { $0.id == row.id }) {
                    order.prePhotoRecords  = prev.prePhotoRecords
                    order.postPhotoRecords = prev.postPhotoRecords
                    order.materialItems    = prev.materialItems
                    order.timelineEvents   = prev.timelineEvents
                }
                return order
            }

            // Restart billing display timer for any order already in active_billing
            if let active = workOrders.first(where: { $0.status == .activeBilling && $0.billingStartTime != nil }) {
                startBillingTimer(for: active.id)
            }
        } catch {
            print("WorkOrderViewModel: fetch failed — \(error)")
        }
        isLoading = false
    }

    private func fetchClientProfiles(clientIds: [UUID]) async {
        guard !clientIds.isEmpty else { return }
        struct ClientProfile: Decodable { let id: UUID; let display_name: String? }
        do {
            let profiles: [ClientProfile] = try await supabase
                .from("profiles")
                .select("id, display_name")
                .in("id", values: clientIds.map { $0.uuidString })
                .execute()
                .value
            for p in profiles {
                let full = (p.display_name ?? "").trimmingCharacters(in: .whitespaces)
                guard !full.isEmpty else { continue }
                // Privacy: "First L." format — never expose full last name to pro
                let parts = full.split(separator: " ")
                let first = String(parts.first ?? Substring(full))
                let lastInitial = parts.count > 1 ? " \(parts[1].prefix(1))." : ""
                clientProfiles[p.id] = first + lastInitial
            }
        } catch {
            print("WorkOrderViewModel: client profile fetch failed — \(error)")
        }
    }

    func subscribeToWorkOrders(proId: UUID) async {
        let channel = supabase.realtimeV2.channel("pro-orders-\(proId)")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "work_orders",
            filter: "pro_id=eq.\(proId)"
        )
        try? await channel.subscribeWithError()
        realtimeChannel = channel
        for await _ in changes {
            await fetchWorkOrders(proId: proId)
        }
    }

    func unsubscribe() async {
        await realtimeChannel?.unsubscribe()
        realtimeChannel = nil
    }

    func markChatRead(for id: UUID) { unreadChatOrderIds.remove(id) }
    func markChatUnread(for id: UUID) { unreadChatOrderIds.insert(id) }

    // MARK: - Helpers

    func index(of id: UUID) -> Int? {
        workOrders.firstIndex { $0.id == id }
    }

    func order(id: UUID) -> WorkOrder? {
        workOrders.first { $0.id == id }
    }

    var activeOrderId: UUID? {
        workOrders.first {
            $0.status == .activeBilling || $0.status == .paused || $0.status == .postWork
        }?.id
    }

    // MARK: - Confirmation

    func confirmJob(for id: UUID) async {
        guard let i = index(of: id), workOrders[i].status == .pending else { return }
        workOrders[i].status = .readyToNavigate
        workOrders[i].addTimelineEvent(.confirmed)
        await transition(id: id, to: "ready_to_navigate")
    }

    // MARK: - Drive

    func startDrive(for id: UUID) async {
        guard let i = index(of: id), workOrders[i].status == .readyToNavigate else { return }
        workOrders[i].status = .enRoute
        isOnline = true
        await transition(id: id, to: "en_route")
    }

    func simulateArrival(for id: UUID) async {
        guard let i = index(of: id), workOrders[i].status == .enRoute else { return }
        workOrders[i].addTimelineEvent(.arrived)
        workOrders[i].status = .preWork  // skip brief .arrived flash — server returns pre_work
        await transition(id: id, to: "arrived")
    }

    // MARK: - Pre Work

    func expandRadius(for id: UUID) async {
        guard let i = index(of: id),
              !workOrders[i].radiusExpanded else { return }
        workOrders[i].radiusExpanded = true
        workOrders[i].addTimelineEvent(.radiusExpanded)
        // Persist flag to Supabase directly (not a status transition)
        do {
            try await supabase
                .from("work_orders")
                .update(["radius_expanded": true])
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            print("WorkOrderViewModel: expandRadius failed — \(error)")
        }
    }

    func fetchPhotos(for id: UUID) async {
        do {
            async let pre = PhotoService.fetchPhotos(workOrderId: id, photoType: "pre")
            async let post = PhotoService.fetchPhotos(workOrderId: id, photoType: "post")
            let (preRecords, postRecords) = try await (pre, post)
            if let i = index(of: id) {
                workOrders[i].prePhotoRecords = preRecords
                workOrders[i].postPhotoRecords = postRecords
            }
        } catch {
            print("WorkOrderViewModel: fetchPhotos failed — \(error)")
        }
    }

    func addPrePhoto(_ image: UIImage, for id: UUID, uploadedBy: UUID) async {
        guard let i = index(of: id),
              workOrders[i].prePhotoRecords.count < Constants.maxPhotosPerGate else { return }
        photoUploadError = nil
        let tempId = UUID()
        workOrders[i].prePhotoRecords.append(
            PhotoRecord(id: tempId, storagePath: "", localImage: image, isUploading: true)
        )
        do {
            let record = try await PhotoService.uploadPhoto(image, photoType: "pre", workOrderId: id, uploadedBy: uploadedBy)
            if let j = index(of: id), let k = workOrders[j].prePhotoRecords.firstIndex(where: { $0.id == tempId }) {
                workOrders[j].prePhotoRecords[k] = record
            }
        } catch {
            if let j = index(of: id), let k = workOrders[j].prePhotoRecords.firstIndex(where: { $0.id == tempId }) {
                workOrders[j].prePhotoRecords.remove(at: k)
            }
            photoUploadError = error.localizedDescription
            print("WorkOrderViewModel: pre photo upload failed — \(error)")
        }
    }

    func removePrePhoto(record: PhotoRecord, for id: UUID) async {
        guard let i = index(of: id),
              let k = workOrders[i].prePhotoRecords.firstIndex(where: { $0.id == record.id }) else { return }
        workOrders[i].prePhotoRecords.remove(at: k)
        guard !record.storagePath.isEmpty else { return }
        do {
            try await PhotoService.deletePhoto(record: record)
        } catch {
            print("WorkOrderViewModel: pre photo delete failed — \(error)")
        }
    }

    func canStartWork(for id: UUID) -> Bool {
        guard let order = order(id: id) else { return false }
        return order.confirmedPrePhotoCount >= Constants.minPhotosRequired
    }

    // MARK: - Billing

    func startWork(for id: UUID, walletVM: WalletViewModel) async {
        guard let i = index(of: id),
              canStartWork(for: id),
              workOrders[i].status == .preWork else { return }
        workOrders[i].addTimelineEvent(.started)
        workOrders[i].status = .activeBilling
        await transition(id: id, to: "active_billing")
        // After server response, billingStartTime is populated — start display timer
        if let j = index(of: id) {
            startBillingTimer(for: workOrders[j].id)
        }
    }

    func pauseWork(for id: UUID) async {
        guard let i = index(of: id),
              workOrders[i].status == .activeBilling || workOrders[i].status == .preWork else { return }
        let prevStatus = workOrders[i].status
        workOrders[i].pausedReturnStatus = prevStatus
        workOrders[i].addTimelineEvent(.paused)
        workOrders[i].status = .paused
        stopBillingTimer()
        cancelRadiusCountdown()
        await transition(id: id, to: "paused")
    }

    func autoPause(for id: UUID) async {
        guard let i = index(of: id) else { return }
        guard workOrders[i].status == .activeBilling else { return }
        workOrders[i].pausedReturnStatus = .activeBilling
        workOrders[i].addTimelineEvent(.autoPause)
        workOrders[i].status = .paused
        stopBillingTimer()
        // Nil out the reference without cancelling — we ARE the radiusTask.
        // Calling cancelRadiusCountdown() here would cancel ourselves and kill
        // the upcoming network call with NSURLErrorCancelled.
        radiusTask = nil
        radiusCountdownSeconds = 0
        await transition(id: id, to: "paused", trigger: "auto_pause")
    }

    func resumeWork(for id: UUID) async {
        guard let i = index(of: id), workOrders[i].status == .paused else { return }
        let returnTo = workOrders[i].pausedReturnStatus ?? .activeBilling
        workOrders[i].addTimelineEvent(.resumed)
        workOrders[i].status = returnTo
        workOrders[i].pausedReturnStatus = nil
        await transition(id: id, to: returnTo.rawValue)
        if returnTo == .activeBilling, let j = index(of: id) {
            startBillingTimer(for: workOrders[j].id)
        }
    }

    // MARK: - Estimates

    func createEstimate(
        for orderId: UUID,
        title: String,
        description: String,
        validForDays: Int,
        estimatedHours: Double,
        estimatedMaterials: Double,
        proposedStartDate: Date
    ) async throws {
        struct Body: Encodable {
            let work_order_id: String
            let title: String
            let description: String
            let valid_for_days: Int
            let estimated_hours: Double
            let estimated_materials: Double
            let proposed_start_date: String
        }
        struct CreateEstimateResponse: Decodable {
            let success: Bool
            let error: String?
        }

        let iso = ISO8601DateFormatter()
        let response: CreateEstimateResponse = try await supabase.functions
            .invoke("create-estimate", options: FunctionInvokeOptions(
                body: Body(
                    work_order_id: orderId.uuidString,
                    title: title,
                    description: description,
                    valid_for_days: validForDays,
                    estimated_hours: estimatedHours,
                    estimated_materials: estimatedMaterials,
                    proposed_start_date: iso.string(from: proposedStartDate)
                )
            ))
        if let errMsg = response.error {
            throw NSError(domain: "VareFy", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
        sentEstimateOrderIds.insert(orderId)
        await fetchEstimates(for: orderId)
    }

    func fetchEstimates(for workOrderId: UUID) async {
        do {
            let rows: [SupabaseEstimate] = try await supabase
                .from("estimates")
                .select()
                .eq("work_order_id", value: workOrderId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            proEstimates[workOrderId] = rows.map { $0.toEstimate() }
        } catch {
            print("WorkOrderVM: fetchEstimates failed — \(error)")
        }
    }

    // MARK: - Materials

    func addMaterialItem(description: String, amount: Double, for id: UUID) {
        guard let i = index(of: id) else { return }
        let item = MaterialLineItem(description: description, amount: amount)
        workOrders[i].materialItems.append(item)
        Task { await persistMaterialItem(item, workOrderId: id) }
        Task { await persistMaterialsTotal(for: id) }
    }

    func removeMaterialItem(at itemIndex: Int, for id: UUID) {
        guard let i = index(of: id),
              itemIndex < workOrders[i].materialItems.count else { return }
        let item = workOrders[i].materialItems[itemIndex]
        workOrders[i].materialItems.remove(at: itemIndex)
        Task { await deleteMaterialItem(id: item.id) }
        Task { await persistMaterialsTotal(for: id) }
    }

    func setReceiptPhoto(_ photo: UIImage, for materialId: UUID, orderId: UUID) {
        guard let i = index(of: orderId),
              let j = workOrders[i].materialItems.firstIndex(where: { $0.id == materialId }) else { return }
        workOrders[i].materialItems[j].receiptPhoto = photo
    }

    private func persistMaterialItem(_ item: MaterialLineItem, workOrderId: UUID) async {
        struct MaterialInsert: Encodable {
            let id: UUID
            let work_order_id: UUID
            let description: String
            let amount: Double
            let added_by: UUID?
        }
        do {
            try await supabase
                .from("material_items")
                .insert(MaterialInsert(
                    id: item.id,
                    work_order_id: workOrderId,
                    description: item.description,
                    amount: item.amount,
                    added_by: currentProId
                ))
                .execute()
        } catch {
            print("WorkOrderViewModel: material item insert failed — \(error)")
        }
    }

    private func deleteMaterialItem(id: UUID) async {
        do {
            try await supabase
                .from("material_items")
                .delete()
                .eq("id", value: id)
                .execute()
        } catch {
            print("WorkOrderViewModel: material item delete failed — \(error)")
        }
    }

    private func persistMaterialsTotal(for id: UUID) async {
        guard let order = order(id: id) else { return }
        let total = order.materialItems.reduce(0.0) { $0 + $1.amount }
        do {
            try await supabase
                .from("work_orders")
                .update(["materials_total": total])
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            print("WorkOrderViewModel: materials total update failed — \(error)")
        }
    }

    // MARK: - Post Work

    func moveToPostWork(for id: UUID) async {
        guard let i = index(of: id), workOrders[i].status == .activeBilling else { return }
        workOrders[i].status = .postWork
        stopBillingTimer()
        cancelRadiusCountdown()
        await transition(id: id, to: "post_work")
    }

    func addPostPhoto(_ image: UIImage, for id: UUID, uploadedBy: UUID) async {
        guard let i = index(of: id),
              workOrders[i].postPhotoRecords.count < Constants.maxPhotosPerGate else { return }
        photoUploadError = nil
        let tempId = UUID()
        workOrders[i].postPhotoRecords.append(
            PhotoRecord(id: tempId, storagePath: "", localImage: image, isUploading: true)
        )
        do {
            let record = try await PhotoService.uploadPhoto(image, photoType: "post", workOrderId: id, uploadedBy: uploadedBy)
            if let j = index(of: id), let k = workOrders[j].postPhotoRecords.firstIndex(where: { $0.id == tempId }) {
                workOrders[j].postPhotoRecords[k] = record
            }
        } catch {
            if let j = index(of: id), let k = workOrders[j].postPhotoRecords.firstIndex(where: { $0.id == tempId }) {
                workOrders[j].postPhotoRecords.remove(at: k)
            }
            photoUploadError = error.localizedDescription
            print("WorkOrderViewModel: post photo upload failed — \(error)")
        }
    }

    func removePostPhoto(record: PhotoRecord, for id: UUID) async {
        guard let i = index(of: id),
              let k = workOrders[i].postPhotoRecords.firstIndex(where: { $0.id == record.id }) else { return }
        workOrders[i].postPhotoRecords.remove(at: k)
        guard !record.storagePath.isEmpty else { return }
        do {
            try await PhotoService.deletePhoto(record: record)
        } catch {
            print("WorkOrderViewModel: post photo delete failed — \(error)")
        }
    }

    func canComplete(for id: UUID) -> Bool {
        guard let order = order(id: id) else { return false }
        return order.confirmedPostPhotoCount >= Constants.minPhotosRequired
    }

    func completeWork(for id: UUID, walletVM: WalletViewModel) async {
        guard let i = index(of: id),
              canComplete(for: id),
              workOrders[i].status == .postWork else { return }
        workOrders[i].addTimelineEvent(.completed)
        workOrders[i].status = .clientReview
        await transition(id: id, to: "client_review")
        // Temporary wallet credit until Phase 10 wires real Supabase transactions
        if let j = index(of: id) {
            walletVM.creditBalance(workOrders[j].totalPaid, description: workOrders[j].serviceTitle)
        }
    }

    // MARK: - Radius

    func setInsideRadius(for id: UUID? = nil) {
        isInsideRadius = true
        cancelRadiusCountdown()
        if let id = id,
           let order = order(id: id),
           order.status == .paused {
            Task { await resumeWork(for: id) }
        }
    }

    func setOutsideRadius(for id: UUID) {
        isInsideRadius = false
        guard let order = order(id: id), order.status == .activeBilling else { return }
        startRadiusCountdown(for: id)
    }

    // MARK: - Billing Timer (server-anchored display timer)

    private func startBillingTimer(for id: UUID) {
        stopBillingTimer()
        guard let i = index(of: id) else { return }

        billingBaseSeconds = workOrders[i].elapsedBillingSeconds
        // Use server billing_start_at as the anchor — corrects for network latency drift
        billingWallClockStart = workOrders[i].billingStartTime ?? Date()

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

    private func stopBillingTimer() {
        billingTask?.cancel()
        billingTask = nil
        billingWallClockStart = nil
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
                await autoPause(for: id)
            }
        }
    }

    private func cancelRadiusCountdown() {
        radiusTask?.cancel()
        radiusTask = nil
        radiusCountdownSeconds = 0
    }

    // MARK: - Edge Function: State Transition

    private func transition(id: UUID, to newStatus: String, trigger: String? = nil) async {
        struct Body: Encodable {
            let work_order_id: String
            let new_status: String
            let trigger: String?
        }

        do {
            let response: TransitionResponse = try await supabase.functions
                .invoke("transition-work-order", options: FunctionInvokeOptions(
                    body: Body(work_order_id: id.uuidString, new_status: newStatus, trigger: trigger)
                ))

            if let serverOrder = response.order, let i = index(of: id) {
                reconcileLocalOrder(from: serverOrder, at: i)
            } else if let errMsg = response.error {
                print("WorkOrderViewModel: transition \(newStatus) rejected — \(errMsg)")
            }
        } catch {
            print("WorkOrderViewModel: transition \(newStatus) error — \(error)")
        }
    }

    // Merge server state into local order, preserving in-flight photo records and local materials.
    private func reconcileLocalOrder(from serverOrder: SupabaseWorkOrder, at i: Int) {
        let prePhotoRecords  = workOrders[i].prePhotoRecords
        let postPhotoRecords = workOrders[i].postPhotoRecords
        let materials        = workOrders[i].materialItems
        let timeline         = workOrders[i].timelineEvents
        let clientName       = workOrders[i].clientName

        var updated = serverOrder.toWorkOrder(clientName: clientName)
        updated.prePhotoRecords  = prePhotoRecords
        updated.postPhotoRecords = postPhotoRecords
        updated.materialItems    = materials
        updated.timelineEvents   = timeline

        workOrders[i] = updated
    }
}
