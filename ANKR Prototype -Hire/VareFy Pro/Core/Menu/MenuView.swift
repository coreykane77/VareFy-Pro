import SwiftUI

struct MenuView: View {
    @Environment(ProfileViewModel.self) private var profileVM

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    profileHeader
                        .padding(.bottom, 36)

                    // Primary nav items
                    navItem("Account", route: .account)
                    navItem("My Services", route: .myServices)
                    navItem("Local Ops", badge: "7", route: .localOps)
                    navItem("H2H",  route: .h2h)
                    navItem("Boss", route: .boss)
                    referItem

                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 16)

                    // Footer items
                    footerItem("App Settings", route: .appSettings)
                    footerItem("Learning", route: .learning)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .popButton()
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        NavigationLink(value: NavRoute.hireProfile) {
            HStack(spacing: 14) {
                if let uiImage = UIImage(named: "Marcus") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.varefyProCyan.opacity(0.4), lineWidth: 1.5))
                } else {
                    Circle()
                        .fill(Color.varefyProCyan.opacity(0.2))
                        .frame(width: 56, height: 56)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profileVM.profile.firstName.uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    if profileVM.profile.isBoss { BOSSBadge() }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: - Nav Item

    @ViewBuilder
    private func navItem(_ label: String, badge: String? = nil, route: NavRoute) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                if let badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.heavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.varefyProCyan)
                        .foregroundStyle(.black)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.highlightRow)
        Divider().background(Color.white.opacity(0.06))
    }

    // MARK: - Refer Item

    @ViewBuilder private var referItem: some View {
        ShareLink(
            item: URL(string: "https://varefypro.app/MarcusR/b364221")!,
            message: Text("Want to get more verified jobs? Join Marcus on VareFy Pro to get started!")
        ) {
            HStack(spacing: 10) {
                Text("Refer")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.highlightRow)
        Divider().background(Color.white.opacity(0.06))
    }

    // MARK: - Footer Item

    @ViewBuilder
    private func footerItem(_ label: String, route: NavRoute) -> some View {
        NavigationLink(value: route) {
            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.highlightRow)
        Divider().background(Color.white.opacity(0.06))
    }
}
