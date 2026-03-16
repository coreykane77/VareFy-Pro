import SwiftUI

struct HireProfileView: View {
    @Environment(ProfileViewModel.self) private var profileVM

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    subtitle
                    profileCard
                    hiresSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: NavRoute.personalInfo) {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
        .popButton()
    }

    // MARK: - Subtitle

    private var subtitle: some View {
        Text("Providing amazing and on-time service to your clients improves your stats so you get hired more often.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        NavigationLink(value: NavRoute.publicProfile) {
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
                    Text("MR")
                        .font(.headline)
                        .foregroundStyle(Color.varefyProCyan)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(profileVM.profile.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(profileVM.profile.businessName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Public Profile")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.varefyProCyan)
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: - Hires Stats

    private var hiresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hires")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(value: "98%", label: "Work Orders Completed")
                statCard(value: "4.8★", label: "Star Rating")
                statCard(value: "147", label: "Jobs Completed")
                statCard(value: "2", label: "Years on Platform", badges: true)
            }
        }
    }

    @ViewBuilder
    private func statCard(value: String, label: String, badges: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if badges {
                HStack(spacing: 8) {
                    BOSSBadge(height: 52)
                    Image(systemName: "shield.fill")
                        .font(.body)
                        .foregroundStyle(Color.varefyProCyan)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.body)
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

}
