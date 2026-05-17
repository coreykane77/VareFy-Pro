import SwiftUI
import Combine

struct WorkOrderDetailView: View {
    let orderId: UUID
    @Binding var path: NavigationPath
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(WalletViewModel.self) private var walletVM
    @Environment(AuthManager.self) private var auth
    @State private var showMaterialsSheet = false
    @State private var showReportIssue = false
    @State private var proHasChatted: Bool = false
    @State private var didAutoNavigate = false
    @State private var photoViewerRecords: [PhotoRecord] = []
    @State private var photoViewerIndex: Int = 0
    @State private var showPhotoViewer = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let order = order {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection(order)
                        detailSection(order)
                        photoHistorySection(order)
                        estimatesSection(order)
                        actionSection(order)
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            } else {
                errorState
            }
        }
        .task(id: orderId) {
            async let photos: () = workOrderVM.fetchPhotos(for: orderId)
            async let estimates: () = workOrderVM.fetchEstimates(for: orderId)
            _ = await (photos, estimates)
        }
        .fullScreenCover(isPresented: $showPhotoViewer) {
            ProPhotoViewer(records: photoViewerRecords, currentIndex: photoViewerIndex)
        }
        .refreshable {
            guard let proId = auth.currentUserId else { return }
            await workOrderVM.fetchWorkOrders(proId: proId)
            await workOrderVM.fetchPhotos(for: orderId)
        }
        .navigationTitle("Work Order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .closeButton()
        .onAppear {
            let status = order?.status
            if !didAutoNavigate, status == .activeBilling || status == .paused {
                didAutoNavigate = true
                path.append(NavRoute.activeBilling(orderId))
                return
            }
            guard status == .pending else { return }
            Task {
                proHasChatted = await ChatViewModel.currentUserHasSentMessage(inChannelFor: orderId)
            }
        }
        .sheet(isPresented: $showReportIssue) {
            ReportIssueSheet(orderId: orderId)
                .environment(workOrderVM)
        }
        .sheet(isPresented: $showMaterialsSheet) {
            if let idx = workOrderVM.index(of: orderId) {
                MaterialsWorksheetView(items: Binding(
                    get: { workOrderVM.workOrders[idx].materialItems },
                    set: { workOrderVM.workOrders[idx].materialItems = $0 }
                ))
            }
        }
    }

    @ViewBuilder
    private func headerSection(_ order: WorkOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.serviceTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text(order.clientName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusPillView(status: order.status)
            }

            Divider().background(Color.white.opacity(0.1))

            infoRow(icon: "location.fill", text: order.address)
            infoRow(icon: "clock.fill", text: order.scheduledTime.formattedAsTime())
            infoRow(icon: "dollarsign.circle.fill", text: "\(order.hourlyRate.formattedAsCurrency())/hr")
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func detailSection(_ order: WorkOrder) -> some View {
        if !order.clientNotes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("CLIENT NOTES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Text(order.clientNotes)
                    .font(.body)
                    .foregroundStyle(.primary.opacity(0.9))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }

        // Materials line item — only editable while job is active
        let editableStatuses: Set<WorkOrderStatus> = [.activeBilling, .paused, .postWork]
        if editableStatuses.contains(order.status) {
            Button { showMaterialsSheet = true } label: {
                HStack {
                    Text("Materials & Supplies")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(order.materialsTotal > 0 ? order.materialsTotal.formattedAsCurrency() : "Add")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        } else if order.materialsTotal > 0 {
            HStack {
                Text("Materials & Supplies")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(order.materialsTotal.formattedAsCurrency())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func photoHistorySection(_ order: WorkOrder) -> some View {
        let allRecords = order.prePhotoRecords + order.postPhotoRecords
        if !allRecords.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("PHOTO RECORD")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary).tracking(1)

                if !order.prePhotoRecords.isEmpty {
                    Text("Before")
                        .font(.caption).foregroundStyle(.secondary)
                    photoHistoryStrip(records: order.prePhotoRecords, allRecords: allRecords)
                }

                if !order.postPhotoRecords.isEmpty {
                    Text("After")
                        .font(.caption).foregroundStyle(.secondary)
                    photoHistoryStrip(records: order.postPhotoRecords, allRecords: allRecords)
                }
            }
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func photoHistoryStrip(records: [PhotoRecord], allRecords: [PhotoRecord]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(records.enumerated()), id: \.element.id) { i, record in
                    Button {
                        photoViewerRecords = allRecords
                        photoViewerIndex   = allRecords.firstIndex(where: { $0.id == record.id }) ?? i
                        showPhotoViewer    = true
                    } label: {
                        ZStack {
                            if let img = record.localImage {
                                Image(uiImage: img).resizable().scaledToFill()
                            } else if let url = record.signedURL {
                                AsyncImage(url: url) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().scaledToFill()
                                    } else {
                                        Color.appBackground
                                    }
                                }
                            } else {
                                Color.appBackground
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func estimatesSection(_ order: WorkOrder) -> some View {
        let estimates = workOrderVM.proEstimates[orderId] ?? []
        if !estimates.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("ESTIMATES SENT")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.8)

                ForEach(estimates) { estimate in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            if let title = estimate.title, !title.isEmpty {
                                Text(title)
                                    .font(.subheadline).fontWeight(.semibold)
                            } else {
                                Text("Estimate")
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                            Spacer()
                            EstimateStatusBadge(status: estimate.status)
                        }

                        HStack(spacing: 16) {
                            Label("\(String(format: "%.1f", estimate.estimatedHours)) hrs",
                                  systemImage: "clock")
                            if estimate.estimatedMaterials > 0 {
                                Label(estimate.estimatedMaterials.formatted(.currency(code: "USD")),
                                      systemImage: "wrench.and.screwdriver")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        HStack {
                            Text("Total")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            Text(estimate.estimatedTotal, format: .currency(code: "USD"))
                                .font(.subheadline).fontWeight(.semibold)
                        }

                        HStack {
                            Text("Proposed start")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(estimate.proposedStartDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    /// True when a *different* order is currently in an active work state.
    private var anotherJobIsActive: Bool {
        if let activeId = workOrderVM.activeOrderId {
            return activeId != orderId
        }
        return false
    }

    @ViewBuilder
    private func actionSection(_ order: WorkOrder) -> some View {
        VStack(spacing: 12) {
            // Primary flow navigation
            switch order.status {
            case .pending:
                if let deadline = order.responseDeadline {
                    ResponseDeadlineBanner(deadline: deadline)
                }
                if proHasChatted {
                    Button {
                        Haptics.medium()
                        Task { await workOrderVM.confirmJob(for: orderId) }
                    } label: {
                        primaryActionLabel("Confirm Job", icon: "checkmark.circle.fill")
                    }
                } else {
                    chatFirstGate
                }

            case .readyToNavigate:
                if anotherJobIsActive {
                    activeJobBlocker
                } else {
                    NavigationLink(value: NavRoute.drive(orderId)) {
                        primaryActionLabel("GO", icon: "arrow.triangle.turn.up.right.circle.fill")
                    }
                    .buttonStyle(.highlightRow)
                }

            case .enRoute:
                if anotherJobIsActive {
                    activeJobBlocker
                } else {
                    NavigationLink(value: NavRoute.drive(orderId)) {
                        primaryActionLabel("GO", icon: "arrow.triangle.turn.up.right.circle.fill")
                    }
                    .buttonStyle(.highlightRow)
                }

            case .arrived, .preWork:
                if anotherJobIsActive {
                    activeJobBlocker
                } else {
                    NavigationLink(value: NavRoute.preWork(orderId)) {
                        primaryActionLabel("Pre Work Photos", icon: "camera.fill")
                    }
                    .buttonStyle(.highlightRow)
                }

            case .activeBilling, .paused:
                NavigationLink(value: NavRoute.activeBilling(orderId)) {
                    primaryActionLabel("Active Job", icon: "timer")
                }
                .buttonStyle(.highlightRow)

            case .postWork:
                NavigationLink(value: NavRoute.postWork(orderId)) {
                    primaryActionLabel("Post Work Photos", icon: "camera.fill")
                }
                .buttonStyle(.highlightRow)

            case .clientReview:
                NavigationLink(value: NavRoute.summary(orderId)) {
                    primaryActionLabel("Work Order Summary", icon: "doc.text.fill")
                }
                .buttonStyle(.highlightRow)

            case .completed, .disputed, .cancelled:
                NavigationLink(value: NavRoute.summary(orderId)) {
                    primaryActionLabel("View Summary", icon: "doc.text.fill")
                }
                .buttonStyle(.highlightRow)
            }

            // Secondary actions row
            NavigationLink(value: NavRoute.chat(orderId)) {
                HStack(spacing: 6) {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.highlightRow)

            // Report an Issue
            Button {
                Haptics.medium()
                showReportIssue = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Text("Report an Issue")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.red.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var activeJobBlocker: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text("Job in progress")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Complete your active job first.")
                    .font(.caption)
                    .opacity(0.7)
            }
            Spacer()
        }
        .foregroundStyle(Color.varefyProGold)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.varefyProGold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.varefyProGold.opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func primaryActionLabel(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.bold)
        }
        .font(.headline)
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.varefyProCyan)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func stubActionButton(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.varefyProCyan)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.85))
        }
    }

    private var chatFirstGate: some View {
        VStack(spacing: 8) {
            NavigationLink(value: NavRoute.chat(orderId)) {
                HStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .foregroundStyle(Color.varefyProCyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Say hello first")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("Tap to message the client before confirming.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan.opacity(0.6))
                }
                .padding(14)
                .background(Color.varefyProCyan.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.varefyProCyan.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Confirm Job")
                    .fontWeight(.bold)
            }
            .font(.headline)
            .foregroundStyle(.black.opacity(0.35))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.varefyProCyan.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var errorState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Work order data unavailable.")
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Estimate Status Badge

private struct EstimateStatusBadge: View {
    let status: EstimateStatus

    var body: some View {
        Text(label)
            .font(.caption2).fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .pending:  return "Awaiting Response"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .expired:  return "Expired"
        }
    }

    private var color: Color {
        switch status {
        case .pending:  return Color.varefyProCyan
        case .accepted: return .green
        case .declined: return .red
        case .expired:  return Color(uiColor: .secondaryLabel)
        }
    }
}

// MARK: - Response Deadline Banner

private struct ResponseDeadlineBanner: View {
    let deadline: Date
    @State private var timeRemaining: TimeInterval = 0

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.title3)
                .foregroundStyle(urgencyColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Response window")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedTime)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(urgencyColor)
            }
            Spacer()
        }
        .padding(14)
        .background(urgencyColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(urgencyColor.opacity(0.25), lineWidth: 1)
        )
        .onAppear { updateTime() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTime()
        }
    }

    private func updateTime() {
        timeRemaining = max(deadline.timeIntervalSinceNow, 0)
    }

    private var isExpired: Bool { timeRemaining <= 0 }

    private var urgencyColor: Color {
        if isExpired { return .red }
        if timeRemaining < 1800 { return .orange }
        return Color.varefyProCyan
    }

    private var formattedTime: String {
        if isExpired { return "Expired — flagged for admin review" }
        let h = Int(timeRemaining) / 3600
        let m = (Int(timeRemaining) % 3600) / 60
        let s = Int(timeRemaining) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d to respond", h, m, s)
        }
        return String(format: "%d:%02d to respond", m, s)
    }
}
