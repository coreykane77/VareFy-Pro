import SwiftUI

struct DocumentsView: View {
    @Environment(ProfileViewModel.self) private var profileVM
    @State private var editingCategory: DocumentCategory? = nil

    private var groupedCategories: [(group: String, categories: [DocumentCategory])] {
        let order = [
            "Identity & Background",
            "Business & Licensing",
            "Insurance",
            "Vehicle",
            "Tax & Financial",
            "Certifications"
        ]
        var dict: [String: [DocumentCategory]] = [:]
        for cat in DocumentCategory.allCases {
            dict[cat.groupLabel, default: []].append(cat)
        }
        return order.compactMap { group in
            guard let cats = dict[group], !cats.isEmpty else { return nil }
            return (group: group, categories: cats)
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    uploadSummaryCard
                    ForEach(groupedCategories, id: \.group) { section in
                        categorySection(section.group, categories: section.categories)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .doneKeyboardToolbar()
        .popButton()
        .sheet(item: $editingCategory) { cat in
            DocumentEditSheet(category: cat)
                .environment(profileVM)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Summary Card

    private var uploadSummaryCard: some View {
        let uploaded = profileVM.profile.documents.filter { $0.isUploaded }.count
        let visible  = profileVM.profile.documents.filter { $0.showOnProfile }.count
        let total    = profileVM.profile.documents.count
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.varefyProCyan.opacity(0.2), lineWidth: 3)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: total > 0 ? CGFloat(uploaded) / CGFloat(total) : 0)
                    .stroke(Color.varefyProCyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                Text("\(uploaded)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.varefyProCyan)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Document Compliance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("\(uploaded) of \(total) uploaded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if visible > 0 {
                    Text("\(visible) visible on public profile")
                        .font(.caption2)
                        .foregroundStyle(Color.varefyProCyan)
                } else if uploaded < total {
                    Text("\(total - uploaded) remaining")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("All documents on file")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Category Section

    @ViewBuilder
    private func categorySection(_ title: String, categories: [DocumentCategory]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element) { idx, cat in
                    documentRow(for: cat)
                    if idx < categories.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.leading, 62)
                    }
                }
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Document Row

    @ViewBuilder
    private func documentRow(for category: DocumentCategory) -> some View {
        let doc        = profileVM.profile.documents.first(where: { $0.category == category })
        let isUploaded = doc?.isUploaded ?? false
        let isVisible  = doc?.showOnProfile ?? false
        let uploadedAt = doc?.uploadedAt

        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isUploaded ? Color.green.opacity(0.12) : Color.appBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon)
                    .font(.body)
                    .foregroundStyle(isUploaded ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    if isVisible {
                        Text("PUBLIC")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.varefyProCyan)
                            .clipShape(Capsule())
                    }
                }
                if isUploaded, let date = uploadedAt {
                    Text("Uploaded \(date.formattedAsDate())")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Text("Not uploaded")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isUploaded {
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                    .font(.title3)
            } else {
                Image(systemName: "arrow.up.circle")
                    .foregroundStyle(Color.varefyProCyan)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.light()
            if isUploaded {
                editingCategory = category
            } else {
                profileVM.uploadDocument(category)
            }
        }
        .contextMenu {
            if !isUploaded {
                Button {
                    Haptics.medium()
                    profileVM.uploadDocument(category)
                } label: {
                    Label("Upload Sample Document", systemImage: "arrow.up.doc.fill")
                }
            } else {
                Button {
                    editingCategory = category
                } label: {
                    Label("Edit Profile Visibility", systemImage: "eye")
                }
                Button(role: .destructive) {
                    Haptics.light()
                    profileVM.removeDocument(category)
                } label: {
                    Label("Remove Document", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - DocumentCategory + Identifiable

extension DocumentCategory: Identifiable {
    var id: String { rawValue }
}

// MARK: - Edit Sheet

private struct DocumentEditSheet: View {
    let category: DocumentCategory
    @Environment(ProfileViewModel.self) private var profileVM
    @Environment(\.dismiss) private var dismiss

    private var docIndex: Int? {
        profileVM.profile.documents.firstIndex(where: { $0.category == category })
    }

    var body: some View {
        @Bindable var vm = profileVM

        VStack(spacing: 0) {
            VStack(spacing: 24) {
                // Header
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: category.icon)
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        if let date = profileVM.profile.documents.first(where: { $0.category == category })?.uploadedAt {
                            Text("Uploaded \(date.formattedAsDate())")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)

                Divider().background(Color.white.opacity(0.08))

                // Public label
                VStack(alignment: .leading, spacing: 8) {
                    Text("PUBLIC LABEL")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)

                    if let idx = docIndex {
                        TextField("e.g. General Liability Policy", text: $vm.profile.documents[idx].publicTitle)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .padding(14)
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Text("Label clients see on your public profile. Leave blank to use the default category name.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)

                // Show on profile toggle
                if let idx = docIndex {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Show on Public Profile")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text("Clients can see this document is on file")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $vm.profile.documents[idx].showOnProfile)
                            .tint(Color.varefyProCyan)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 20)
                }

                Divider().background(Color.white.opacity(0.08))

                Button(role: .destructive) {
                    Haptics.medium()
                    profileVM.removeDocument(category)
                    dismiss()
                } label: {
                    Label("Remove Document", systemImage: "trash")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                }
            }

            Spacer()
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}
