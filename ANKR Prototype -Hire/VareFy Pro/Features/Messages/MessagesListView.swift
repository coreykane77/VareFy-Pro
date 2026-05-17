import SwiftUI
import StreamChat

// MARK: - Models

enum InboxCategory: String, CaseIterable {
    case all = "All"
    case client = "Client"
    case integrityTeam = "Integrity Team"
    case notifications = "Notifications"
}

enum InboxItemType {
    case client(orderId: UUID)
    case integrityTeam
    case notification
}

struct InboxItem: Identifiable {
    let id = UUID()
    let type: InboxItemType
    let sender: String
    let subject: String
    let preview: String
    let time: String
    let isUnread: Bool
    let avatarIcon: String?   // nil = use initials
    let avatarColor: Color
}

// MARK: - View

private struct ChannelState {
    var unread: Bool = false
    var preview: String = ""
    var time: Date = .distantPast
}

struct MessagesListView: View {
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(AuthManager.self) private var authManager
    @State private var selectedCategory: InboxCategory = .all
    @State private var selectedItem: InboxItem? = nil
    @State private var channelStates: [UUID: ChannelState] = [:]

    private var allItems: [InboxItem] {
        var items: [InboxItem] = []

        // One thread per assigned work order — sorted newest first
        let orders = workOrderVM.workOrders.sorted {
            let aTime = channelStates[$0.id]?.time ?? $0.scheduledTime
            let bTime = channelStates[$1.id]?.time ?? $1.scheduledTime
            return aTime > bTime
        }
        for order in orders {
            let state = channelStates[order.id]
            let isUnread = state?.unread ?? workOrderVM.unreadChatOrderIds.contains(order.id)
            let preview = state?.preview ?? "Tap to open chat"
            let time = state?.time.inboxTimeString ?? order.scheduledTime.inboxTimeString
            items.append(.init(
                type: .client(orderId: order.id),
                sender: order.clientName,
                subject: "\(order.serviceTitle) · \(order.status.displayName)",
                preview: preview,
                time: time,
                isUnread: isUnread,
                avatarIcon: nil,
                avatarColor: Color.varefyProCyan
            ))
        }

        // Integrity Team
        items.append(.init(
            type: .integrityTeam,
            sender: "Integrity Team",
            subject: "Resolution stack completion",
            preview: "Payment issued — Invoice #0147 has been resolved and funds disbursed.",
            time: "Yesterday",
            isUnread: false,
            avatarIcon: "shield.fill",
            avatarColor: Color.varefyProCyan
        ))
        items.append(.init(
            type: .integrityTeam,
            sender: "Integrity Team",
            subject: "Client issue report",
            preview: "A dispute was opened on Invoice #0147. Our team is reviewing the record.",
            time: "2d ago",
            isUnread: false,
            avatarIcon: "shield.fill",
            avatarColor: Color.varefyProCyan
        ))
        items.append(.init(
            type: .integrityTeam,
            sender: "Integrity Team",
            subject: "Issue report resolved",
            preview: "Invoice #0147 — reviewed and closed. No action required. Same-day resolution.",
            time: "2d ago",
            isUnread: false,
            avatarIcon: "shield.fill",
            avatarColor: Color.varefyProCyan
        ))

        // Notifications
        items.append(.init(
            type: .notification,
            sender: "VareFy Pro",
            subject: "3 things to increase your revenue",
            preview: "Hires who do these three things earn 40% more on average. See what they are.",
            time: "3d ago",
            isUnread: false,
            avatarIcon: "bell.fill",
            avatarColor: .purple
        ))
        items.append(.init(
            type: .notification,
            sender: "VareFy Pro",
            subject: "System maintenance alert",
            preview: "Scheduled downtime Mon March 3rd, 2:00–3:00 AM CT. No action needed.",
            time: "4d ago",
            isUnread: false,
            avatarIcon: "bell.fill",
            avatarColor: .purple
        ))

        return items
    }

    private var filteredItems: [InboxItem] {
        switch selectedCategory {
        case .all:
            return allItems
        case .client:
            return allItems.filter { if case .client = $0.type { return true }; return false }
        case .integrityTeam:
            return allItems.filter { if case .integrityTeam = $0.type { return true }; return false }
        case .notifications:
            return allItems.filter { if case .notification = $0.type { return true }; return false }
        }
    }

    private var unreadCount: Int { allItems.filter(\.isUnread).count }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                categoryPills.padding(.vertical, 12)

                if filteredItems.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredItems) { item in
                                inboxRow(item)
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.leading, 76)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
        .task { await loadChannelStates() }
        .sheet(item: $selectedItem) { item in
            InboxDetailSheet(item: item)
        }
    }

    // MARK: - Stream Channel State

    private func loadChannelStates() async {
        guard let client = ChatViewModel.client else { return }
        var controllers: [ChatChannelController] = []
        for order in workOrderVM.workOrders {
            let channelId = ChannelId(type: .messaging, id: "work_order_\(order.id.uuidString.lowercased())")
            let controller = client.channelController(for: channelId)
            controllers.append(controller)
            let _: Error? = await withCheckedContinuation { cont in
                controller.synchronize { cont.resume(returning: $0) }
            }
            let unread = (controller.channel?.unreadCount.messages ?? 0) > 0
            let lastMsg = Array(controller.messages).filter { $0.type == .regular }.first
            channelStates[order.id] = ChannelState(
                unread: unread,
                preview: lastMsg?.text ?? "",
                time: lastMsg?.createdAt ?? order.scheduledTime
            )
            if unread { workOrderVM.markChatUnread(for: order.id) }
        }
    }

    // MARK: - Row Router

    @ViewBuilder
    private func inboxRow(_ item: InboxItem) -> some View {
        if case .client(let orderId) = item.type {
            NavigationLink(value: NavRoute.chat(orderId)) {
                InboxRowView(item: item)
            }
            .buttonStyle(.highlightRow)
        } else {
            Button {
                Haptics.light()
                selectedItem = item
            } label: {
                InboxRowView(item: item)
            }
            .buttonStyle(.highlightRow)
        }
    }

    // MARK: - Pills

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InboxCategory.allCases, id: \.self) { category in
                    let isSelected = selectedCategory == category
                    let showBadge = (category == .all || category == .client) && unreadCount > 0

                    Button {
                        Haptics.light()
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(isSelected ? .semibold : .regular)
                                .foregroundStyle(isSelected ? .black : .white)
                            if showBadge {
                                Text("\(unreadCount)")
                                    .font(.caption2)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(isSelected ? .black : Color.varefyProCyan)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? Color.black.opacity(0.2) : Color.varefyProCyan.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.varefyProCyan : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.varefyProCyan.opacity(0.4))
            Text("No messages")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Inbox Row View

private struct InboxRowView: View {
    let item: InboxItem

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(item.avatarColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Group {
                            if let icon = item.avatarIcon {
                                Image(systemName: icon)
                                    .font(.subheadline)
                                    .foregroundStyle(item.avatarColor)
                            } else {
                                Text(initials(for: item.sender))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(item.avatarColor)
                            }
                        }
                    )
                if item.isUnread {
                    Circle()
                        .fill(Color.varefyProCyan)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                        .offset(x: 2, y: -2)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.sender)
                        .font(.subheadline)
                        .fontWeight(item.isUnread ? .bold : .medium)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(item.time)
                        .font(.caption2)
                        .foregroundStyle(item.isUnread ? Color.varefyProCyan : .gray)
                }
                Text(item.subject)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(item.avatarColor.opacity(0.8))
                    .lineLimit(1)
                Text(item.preview)
                    .font(.caption)
                    .foregroundStyle(item.isUnread ? .white.opacity(0.85) : .gray)
                    .lineLimit(1)
            }

            if case .client = item.type {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(item.isUnread ? Color.varefyProCyan.opacity(0.04) : Color.clear)
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
    }
}

// MARK: - Inbox Detail Sheet

private struct InboxDetailSheet: View {
    let item: InboxItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack(spacing: 14) {
                            Circle()
                                .fill(item.avatarColor.opacity(0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: item.avatarIcon ?? "person.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(item.avatarColor)
                                )
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.sender)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Text(item.time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider().background(Color.white.opacity(0.08))

                        Text(item.subject)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text(fullBody(for: item))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }

    private func fullBody(for item: InboxItem) -> String {
        switch item.subject {
        case "Resolution stack completion":
            return "Your dispute on Invoice #0147 has been fully reviewed and resolved by the VareFy Pro Integrity Team.\n\nAll required documentation — including pre-work photos, post-work photos, GPS arrival record, and the verified timeline — were confirmed to meet platform standards.\n\nPayment has been released and disbursed to your wallet. No further action is needed on your end.\n\nIf you have questions, reply to this message or contact support."
        case "Issue report resolved":
            return "The issue report filed against Invoice #0147 has been reviewed and closed — same day.\n\nOur Integrity Team examined all job records on file: pre-work photos, post-work photos, GPS arrival verification, and the verified billing timeline. All documentation met platform standards.\n\nThe report was dismissed. Your account standing is unaffected.\n\nNo further action is required on your end. This case is now closed."
        case "Client issue report":
            return "A client has submitted an issue report referencing Invoice #0147.\n\nThe VareFy Pro Integrity Team has opened a review and will examine all verified job records on file, including your photo documentation and timeline.\n\nYou do not need to take action at this time. If we need additional information, a team member will reach out directly.\n\nResolution timelines:\n• Simple cases: 1–4 hours\n• Normal cases: under 24 hours\n• Complex cases: up to 48 hours"
        case "3 things to increase your revenue":
            return "Hires who do these three things consistently earn 40% more on average:\n\n1. Respond to new job requests within 15 minutes. Fast response rates directly improve your match score and placement in job queues.\n\n2. Complete jobs with zero photo rejections. Full pre and post photo sets — without flags — signal reliability and unlock priority routing.\n\n3. Maintain a rating above 4.7. Clients filter by rating. Staying above 4.7 keeps you visible to the highest-paying clients on the platform.\n\nThese aren't hacks — they're the behaviors the system is designed to reward."
        case "System maintenance alert":
            return "VareFy Pro will undergo scheduled system maintenance on Monday, March 3rd from 2:00 AM to 3:00 AM Central Time.\n\nDuring this window, the app may be temporarily unavailable or experience reduced functionality. Active work orders will not be affected.\n\nNo action is required on your part. We recommend completing any pending submissions before the maintenance window begins.\n\nWe apologize for any inconvenience and appreciate your patience."
        default:
            return item.preview
        }
    }
}
