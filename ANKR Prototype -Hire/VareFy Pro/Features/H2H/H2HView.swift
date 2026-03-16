import SwiftUI

struct H2HView: View {
    @State private var searchText = ""

    private var filteredHires: [PublicHireProfile] {
        if searchText.isEmpty { return PublicHireProfile.allHires }
        return PublicHireProfile.allHires.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.services.contains { $0.label.localizedCaseInsensitiveContains(searchText) } ||
            $0.servingArea.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    Text("See how your peers stack up. Get inspired by the best in your area.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)

                    ForEach(filteredHires, id: \.name) { hire in
                        NavigationLink(value: NavRoute.publicProfileDetail(hire)) {
                            H2HHireCard(hire: hire)
                        }
                        .buttonStyle(.highlightRow)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Hire to Hire")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search hires, services, area")
        .popButton()
    }
}

// MARK: - Hire Card

struct H2HHireCard: View {
    let hire: PublicHireProfile

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Group {
                if let imageName = hire.imageName, let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Color.varefyProCyan.opacity(0.15)
                        Text(String(hire.name.prefix(1)))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
            .overlay(Circle().stroke(hire.isBoss ? Color.varefyProGold.opacity(0.6) : Color.varefyProCyan.opacity(0.2), lineWidth: 1.5))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(hire.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if hire.isBoss { BOSSBadge() }
                    if hire.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.varefyProGold)
                    Text(String(format: "%.1f", hire.rating))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProGold)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("\(hire.jobsCompleted) jobs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("\(hire.yearsOnPlatform)yr")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

                // Service tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(hire.services, id: \.label) { service in
                            Text(service.label)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.varefyProCyan.opacity(0.1))
                                .foregroundStyle(Color.varefyProCyan)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.4))
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hire.isBoss ? Color.varefyProGold.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: hire.isBoss ? Color.varefyProGold.opacity(0.12) : .clear, radius: 8, x: 0, y: 0)
    }
}
