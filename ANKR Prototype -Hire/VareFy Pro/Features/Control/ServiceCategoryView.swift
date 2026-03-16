import SwiftUI

// MARK: - ServiceCategoryView
// Collapsed list of service groups. Tap any group to configure it.

struct ServiceCategoryView: View {
    let category: ServiceCategory
    @Environment(ServicesViewModel.self) private var servicesVM

    private var groups: [ServiceGroup] {
        servicesVM.offeringGroups(in: category)
    }

    private var hasAnyEnabled: Bool {
        groups.contains { g in g.offerings.contains { $0.isEnabled } }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    categoryHeader
                    ForEach(groups) { group in
                        NavigationLink(value: NavRoute.serviceGroup(ServiceGroupRoute(category: category, group: group))) {
                            groupRow(group)
                        }
                        .buttonStyle(.plain)
                    }

                    if hasAnyEnabled {
                        Button(role: .destructive) {
                            servicesVM.disable(category: category)
                        } label: {
                            Text("Disable All in This Category")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }

    // MARK: - Category Header

    @ViewBuilder
    private var categoryHeader: some View {
        ZStack(alignment: .bottomLeading) {
            if let uiImage = UIImage(named: category.representativeImageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).fill(.black.opacity(0.45)))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .frame(height: 140)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                let total = groups.reduce(0) { $0 + $1.offerings.filter { $0.isEnabled }.count }
                if total > 0 {
                    Text("\(total) task\(total == 1 ? "" : "s") enabled")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan)
                } else {
                    Text("\(groups.count) service\(groups.count == 1 ? "" : "s") available")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(16)
        }
        .padding(.top, 8)
    }

    // MARK: - Group Row

    @ViewBuilder
    private func groupRow(_ group: ServiceGroup) -> some View {
        HStack(spacing: 14) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackground)
                .frame(width: 56, height: 56)
                .overlay {
                    if let imageName = group.imageName, let uiImage = UIImage(named: imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Labels
            VStack(alignment: .leading, spacing: 3) {
                Text(group.groupName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                let enabledCount = group.offerings.filter { $0.isEnabled }.count
                if enabledCount > 0 {
                    Text("\(enabledCount) of \(group.offerings.count) tasks enabled")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan)
                } else {
                    Text("\(group.offerings.count) task\(group.offerings.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status indicator + chevron
            if group.offerings.contains(where: { $0.isEnabled }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.varefyProCyan)
                    .font(.system(size: 18))
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Route helper for NavigationLink

struct ServiceGroupRoute: Hashable {
    let category: ServiceCategory
    let group: ServiceGroup
}
