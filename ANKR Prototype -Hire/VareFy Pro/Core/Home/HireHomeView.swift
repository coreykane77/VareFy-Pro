import SwiftUI

enum AppTab {
    case home, workOrders, wallet, inbox, menu
}

struct HireHomeView: View {
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(WalletViewModel.self) private var walletVM
    @Environment(AuthManager.self) private var authManager

    @State private var path = NavigationPath()
    @State private var activeTab: AppTab = .home
    @State private var mapLayerStyle: MapLayerStyle = .appleMaps

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                mapWithOverlay
            }
            .navigationBarHidden(true)
            .navigationDestination(for: NavRoute.self) { route in

                switch route {
                case .messagesList:
                    MessagesListView()
                case .workOrdersList:
                    WorkOrdersListView()
                case .workOrderDetail(let id):
                    WorkOrderDetailView(orderId: id)
                case .confirmation(let id):
                    HireConfirmationView(orderId: id)
                case .drive(let id):
                    DriveView(orderId: id)
                case .preWork(let id):
                    PreWorkPhotoView(orderId: id)
                case .activeBilling(let id):
                    ActiveBillingView(orderId: id)
                case .postWork(let id):
                    PostWorkPhotoView(orderId: id)
                case .summary(let id):
                    CompletionSummaryView(orderId: id)
                case .chat(let id):
                    ChatView(orderId: id)
                case .wallet:
                    WalletOverviewView()
                case .managePayout:
                    ManagePayoutView()
                case .appSettings:
                    AppSettingsView()
                case .control:
                    FieldControlView()
                case .myServices:
                    MyServicesView()
                case .serviceCategory(let category):
                    ServiceCategoryView(category: category)
                case .serviceGroup(let route):
                    ServiceGroupDetailView(category: route.category, group: route.group)
                case .localOps:
                    LocalOpsView()
                case .hireProfile:
                    HireProfileView()
                case .publicProfile:
                    PublicProfileView(isOwnProfile: true)
                case .publicProfileDetail(let hire):
                    PublicProfileView(profile: hire)
                case .h2h:
                    H2HView()
                case .boss:
                    BossView()
                case .menu:
                    MenuView()
                case .account:
                    AccountView()
                case .termsOfService:
                    TermsOfServiceView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .learning:
                    LearningView()
                case .personalInfo:
                    PersonalInfoView()
                case .documents:
                    DocumentsView()
                case .vehicle:
                    VehicleView()
                case .placeholder(let title):
                    PlaceholderView(title: title)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomTabBar
        }

        .environment(\.dismissToRoot, {
            path = NavigationPath()
            activeTab = .home
        })
        .task {
            guard let proId = authManager.currentUserId else { return }
            await workOrderVM.fetchWorkOrders(proId: proId)
            await workOrderVM.subscribeToWorkOrders(proId: proId)
        }
    }

    // MARK: - Map + Overlay

    private var mapWithOverlay: some View {
        ZStack {
            MapBackgroundView()

            VStack(spacing: 0) {
                topControls
                Spacer()
            }

            // Field control — bottom-right, thumb-reachable
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fieldControlButton
                }
                .padding(.bottom, 146)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Top Controls

    private var topControls: some View {
        HStack(alignment: .top, spacing: 12) {
            // Balance pill
            HStack(spacing: 4) {
                Text(walletVM.balance.formattedAsCurrency())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.varefyProLime)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .clipShape(Capsule())

            Spacer()

            // Map layer toggle
            Button {
                Haptics.selection()
                withAnimation(.easeInOut(duration: 0.25)) {
                    mapLayerStyle = mapLayerStyle.next
                }
            } label: {
                VStack(spacing: 2) {
                    mapLayerIcon(for: mapLayerStyle.next)
                    Text(mapLayerStyle.next.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Field Control Button (bottom-right, thumb-reachable)

    private var fieldControlButton: some View {
        Button {
            Haptics.light()
            path.append(NavRoute.control)
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.85))
                .clipShape(Circle())
        }
        .padding(.trailing, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Bottom Tab Bar

    private var bottomTabBar: some View {
        VStack(spacing: 0) {
            // Work Orders pill — home screen only
            if path.isEmpty {
                Button {
                    Haptics.medium()
                    activeTab = .workOrders
                    path = NavigationPath()
                    path.append(NavRoute.workOrdersList)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "list.clipboard.fill")
                            .font(.title2)
                        Text("Work Orders")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.varefyProCyan)
                    .clipShape(Capsule())
                    .shadow(color: Color.varefyProCyan.opacity(0.35), radius: 10, y: 3)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 10)
                .background(Color.black)
            }

            // Four-tab row
            HStack(spacing: 0) {
                // VareFy Pro logo home button
                Button {
                    Haptics.light()
                    activeTab = .home
                    path = NavigationPath()
                } label: {
                    VStack(spacing: 4) {
                        Image("VFYX")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(width: 34, height: 34)
                            .grayscale(activeTab == .home ? 0.0 : 1.0)
                        Text("Home")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(activeTab == .home ? Color.varefyProCyan : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }

                tabButton(icon: "wallet.pass.fill", label: "Wallet", tab: .wallet) {
                    activeTab = .wallet
                    path = NavigationPath()
                    path.append(NavRoute.wallet)
                }
                tabButton(
                    icon: "message.fill",
                    label: "Inbox",
                    tab: .inbox,
                    badge: workOrderVM.hasUnreadChats
                ) {
                    activeTab = .inbox
                    path = NavigationPath()
                    path.append(NavRoute.messagesList)
                }
                tabButton(
                    icon: "line.3.horizontal",
                    label: "Menu",
                    tab: .menu
                ) {
                    activeTab = .menu
                    path = NavigationPath()
                    path.append(NavRoute.menu)
                }
            }
            .frame(height: Constants.bottomBarHeight)
            .background(Color.black)
        }
    }

    @ViewBuilder
    private func mapLayerIcon(for style: MapLayerStyle) -> some View {
        switch style {
        case .appleMaps:
            Image(systemName: "apple.logo")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        case .waze:
            Image("3")
                .resizable()
                .scaledToFit()
                .colorInvert()
                .frame(width: 18, height: 18)
        case .google:
            Image("4")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        }
    }

    @ViewBuilder
    private func tabButton(
        icon: String,
        label: String,
        tab: AppTab,
        badge: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let isActive = activeTab == tab
        Button {
            Haptics.light()
            action()
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isActive ? Color.varefyProCyan : .gray)
                    if badge {
                        Circle()
                            .fill(Color.varefyProCyan)
                            .frame(width: 8, height: 8)
                            .offset(x: 5, y: -3)
                    }
                }
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isActive ? Color.varefyProCyan : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
    }
}
