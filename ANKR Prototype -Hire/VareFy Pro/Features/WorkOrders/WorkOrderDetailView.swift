import SwiftUI
import Combine

struct WorkOrderDetailView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(WalletViewModel.self) private var walletVM
    @State private var showMaterialsSheet = false
    @State private var showReportIssue = false
    @State private var proHasChatted: Bool = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let order = order {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection(order)
                        detailSection(order)
                        actionSection(order)
                    }
                    .padding(16)
                    .padding(.bottom, 80)
                }
            } else {
                errorState
            }
        }
        .navigationTitle("Work Order")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .closeButton()
        .onAppear {
            guard order?.status == .pending else { return }
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

        // Materials line item — tappable worksheet
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
                    NavigationLink(value: NavRoute.confirmation(orderId)) {
                        primaryActionLabel("Confirm Job", icon: "checkmark.circle.fill")
                    }
                    .buttonStyle(.highlightRow)
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
            HStack(spacing: 10) {
                Image(systemName: "message.fill")
                    .foregroundStyle(Color.varefyProCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Say hello first")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Send the client a message before confirming.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.varefyProCyan.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.varefyProCyan.opacity(0.25), lineWidth: 1)
            )

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
