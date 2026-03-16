import SwiftUI

struct AccountView: View {
    @Environment(ProfileViewModel.self) private var profileVM

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Personal Info — full name, contact, address
                    accountRow(
                        icon: "person.fill",
                        label: "Personal Info",
                        subtitle: profileVM.profile.fullName,
                        route: .personalInfo
                    )
                    Divider().background(Color.white.opacity(0.06))
                    vehicleRow
                    Divider().background(Color.white.opacity(0.06))
                    crewRow
                    Divider().background(Color.white.opacity(0.06))
                    accountRow(
                        icon: "doc.fill",
                        label: "Documents",
                        subtitle: documentsSubtitle,
                        route: .documents
                    )
                    Divider().background(Color.white.opacity(0.06))
                    accountRow(
                        icon: "creditcard.fill",
                        label: "Payment Methods",
                        subtitle: nil,
                        route: .placeholder("Payment Methods")
                    )
                    Divider().background(Color.white.opacity(0.06))
                    accountRow(
                        icon: "building.columns.fill",
                        label: "Tax Info",
                        subtitle: nil,
                        route: .placeholder("Tax Info")
                    )
                    Divider().background(Color.white.opacity(0.06))
                    accountRow(
                        icon: "info.circle.fill",
                        label: "About",
                        subtitle: nil,
                        route: .placeholder("About")
                    )
                    Divider().background(Color.white.opacity(0.06))
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }

    // MARK: - Computed

    private var documentsSubtitle: String {
        let uploaded = profileVM.profile.documents.filter { $0.isUploaded }.count
        let total = profileVM.profile.documents.count
        return "\(uploaded) of \(total) uploaded"
    }

    // MARK: - Vehicle Row

    private var vehicleRow: some View {
        NavigationLink(value: NavRoute.vehicle) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appCard)
                        .frame(width: 48, height: 48)
                    Image(systemName: "car.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Vehicles")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(profileVM.profile.vehicleDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: - Crew Row

    private var crewRow: some View {
        NavigationLink(value: NavRoute.placeholder("Crew")) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appCard)
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Crew")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(profileVM.profile.crewMembers.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: - Generic Row

    @ViewBuilder
    private func accountRow(icon: String, label: String, subtitle: String?, route: NavRoute) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appCard)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(.highlightRow)
    }
}
