import SwiftUI

struct DrawerMenuView: View {
    @Binding var isOpen: Bool
    @Binding var path: NavigationPath
    @Environment(ProfileViewModel.self) private var profileVM
    @Environment(WorkOrderViewModel.self) private var workOrderVM

    /// Persisted key of the most recently tapped drawer item.
    @AppStorage("drawer_last_route") private var lastRouteKey: String = ""

    private let otherMenuItems: [(String, String, NavRoute)] = [
        ("person.2.fill",          "H2H",        .placeholder("H2H")),
        ("briefcase.fill",         "Boss",       .boss),
        ("gift.fill",              "Refer",      .placeholder("Refer")),
    ]

    private let footerItems: [(String, String, NavRoute)] = [
        ("gearshape.fill",         "App Settings", .appSettings),
        ("graduationcap.fill",     "Learning",     .placeholder("Learning")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            DrawerHeaderView(profile: profileVM.profile) {
                navigate(to: .hireProfile)
            }

            ScrollView {
                VStack(spacing: 0) {
                    // Wallet — fully implemented
                    drawerRow(icon: "wallet.pass.fill", label: "Wallet", route: .wallet) {
                        navigate(to: .wallet)
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // Messages — with unread badge
                    badgedDrawerRow(
                        icon: "message.fill",
                        label: "Messages",
                        route: .messagesList,
                        badge: workOrderVM.hasUnreadChats
                            ? "\(workOrderVM.unreadChatOrderIds.count)"
                            : nil,
                        badgeStyle: .chat
                    ) {
                        navigate(to: .messagesList)
                    }
                    Divider().background(Color.white.opacity(0.05))

                    // Local Ops — fully implemented
                    badgedDrawerRow(
                        icon: "map.fill",
                        label: "Local Ops",
                        route: .localOps,
                        badge: "7",
                        badgeStyle: .ops
                    ) {
                        navigate(to: .localOps)
                    }
                    Divider().background(Color.white.opacity(0.05))

                    ForEach(otherMenuItems, id: \.1) { icon, label, route in
                        drawerRow(icon: icon, label: label, route: route) {
                            navigate(to: route)
                        }
                        Divider().background(Color.white.opacity(0.05))
                    }

                    Spacer().frame(height: 24)

                    // Footer
                    ForEach(footerItems, id: \.1) { icon, label, route in
                        drawerRow(icon: icon, label: label, route: route, tint: .gray) {
                            navigate(to: route)
                        }
                        Divider().background(Color.white.opacity(0.05))
                    }
                }
            }

            Spacer()
        }
        .background(Color.appBackground)
        .ignoresSafeArea(edges: .vertical)
    }

    // MARK: Row Helpers

    @ViewBuilder
    private func drawerRow(icon: String, label: String, route: NavRoute, tint: Color = .varefyProCyan, action: @escaping () -> Void) -> some View {
        let active = routeKey(route) == lastRouteKey && !lastRouteKey.isEmpty
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(active ? Color.varefyProCyan : tint)
                    .frame(width: 24)
                Text(label)
                    .font(.body)
                    .fontWeight(active ? .semibold : .medium)
                    .foregroundStyle(active ? Color.varefyProCyan : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(active ? Color.varefyProCyan.opacity(0.5) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .background(active ? Color.varefyProCyan.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.highlightRow)
    }

    @ViewBuilder
    private func badgedDrawerRow(icon: String, label: String, route: NavRoute, badge: String?, badgeStyle: DrawerBadgeView.Style, action: @escaping () -> Void) -> some View {
        let active = routeKey(route) == lastRouteKey && !lastRouteKey.isEmpty
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(active ? Color.varefyProCyan : Color.varefyProCyan)
                    .frame(width: 24)
                Text(label)
                    .font(.body)
                    .fontWeight(active ? .semibold : .medium)
                    .foregroundStyle(active ? Color.varefyProCyan : .primary)
                if let badge {
                    DrawerBadgeView(text: badge, style: badgeStyle)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(active ? Color.varefyProCyan.opacity(0.5) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .background(active ? Color.varefyProCyan.opacity(0.08) : Color.clear)
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: Navigation

    private func navigate(to route: NavRoute) {
        Haptics.light()
        lastRouteKey = routeKey(route)
        path.append(route)
    }

    /// Maps a NavRoute to a stable string key for AppStorage.
    private func routeKey(_ route: NavRoute) -> String {
        switch route {
        case .wallet:                    return "wallet"
        case .messagesList:              return "messages"
        case .workOrdersList:            return "workOrders"
        case .appSettings:               return "appSettings"
        case .control:                   return "control"
        case .localOps:                  return "local_ops"
        case .hireProfile:               return "hire_profile"
        case .placeholder(let title):    return title.lowercased().replacingOccurrences(of: " ", with: "_")
        default:                         return ""
        }
    }
}
