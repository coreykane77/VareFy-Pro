import SwiftUI

// MARK: - MyServicesView

struct MyServicesView: View {
    @Environment(ServicesViewModel.self) private var servicesVM
    @State private var searchQuery: String = ""

    // MARK: Filtered results

    private var aliasTargets: [String] {
        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        return ServiceOffering.searchAliases
            .filter { $0.key.localizedCaseInsensitiveContains(q) }
            .flatMap { $0.value }
    }

    private var categoryResults: [ServiceCategory] {
        guard !searchQuery.isEmpty else { return [] }
        let q = searchQuery
        let targets = aliasTargets
        return ServiceCategory.allCases.filter { category in
            category.rawValue.localizedCaseInsensitiveContains(q) ||
            targets.contains { category.rawValue.localizedCaseInsensitiveContains($0) }
        }
    }

    private var offeringResults: [ServiceOffering] {
        guard !searchQuery.isEmpty else { return [] }
        let q = searchQuery
        let targets = aliasTargets
        var seen = Set<UUID>()
        return servicesVM.offerings.filter { offering in
            offering.name.localizedCaseInsensitiveContains(q) ||
            offering.groupName.localizedCaseInsensitiveContains(q) ||
            targets.contains { offering.name.localizedCaseInsensitiveContains($0) }
        }.filter { seen.insert($0.id).inserted }
    }

    private var noResults: Bool {
        !searchQuery.isEmpty && categoryResults.isEmpty && offeringResults.isEmpty
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            List {
                if searchQuery.isEmpty {
                    Section {
                        ForEach(ServiceCategory.allCases) { category in
                            NavigationLink(value: NavRoute.serviceCategory(category)) {
                                categoryRow(category)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Select categories to manage")
                            Spacer()
                            if servicesVM.totalEnabled > 0 {
                                Text("\(servicesVM.totalEnabled) active")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.varefyProCyan)
                            }
                        }
                    }
                } else {
                    if !categoryResults.isEmpty {
                        Section("Categories") {
                            ForEach(categoryResults) { category in
                                NavigationLink(value: NavRoute.serviceCategory(category)) {
                                    categoryRow(category)
                                }
                            }
                        }
                    }

                    if !offeringResults.isEmpty {
                        Section("Tasks") {
                            ForEach(offeringResults) { offering in
                                NavigationLink(value: NavRoute.serviceCategory(offering.category)) {
                                    taskSearchRow(offering)
                                }
                            }
                        }
                    }

                    if noResults {
                        Section {
                            Text("No results for \"\(searchQuery)\"")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "Search services or tasks")
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("My Services")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }

    // MARK: Category Row — image first

    @ViewBuilder
    private func categoryRow(_ category: ServiceCategory) -> some View {
        HStack(spacing: 14) {
            // Service image — primary visual anchor
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appBackground)
                .frame(width: 56, height: 56)
                .overlay {
                    if let uiImage = UIImage(named: category.representativeImageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: category.systemImage)
                            .font(.title3)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                let groupCount = servicesVM.enabledGroupCount(in: category)
                let taskCount  = servicesVM.enabledTaskCount(in: category)
                if taskCount > 0 {
                    Text("\(groupCount) service\(groupCount == 1 ? "" : "s") · \(taskCount) task\(taskCount == 1 ? "" : "s") enabled")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan)
                } else {
                    Text("Not configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if servicesVM.isEnabled(category) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.varefyProCyan)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Task Search Row

    @ViewBuilder
    private func taskSearchRow(_ offering: ServiceOffering) -> some View {
        HStack(spacing: 14) {
            if let imageName = offering.imageName,
               let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(offering.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Text(offering.groupName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if offering.isEnabled, let rate = offering.hourlyRate {
                    Text("$\(String(format: "%.0f", rate)) / hr")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }

            Spacer()

            if offering.isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.varefyProCyan)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 2)
    }
}
