import SwiftUI

// MARK: - ServiceGroupDetailView
// Full configuration for a single service group: tasks, rates, bio, portfolio, disclaimer.

struct ServiceGroupDetailView: View {
    let category: ServiceCategory
    let group: ServiceGroup

    @Environment(ServicesViewModel.self) private var servicesVM
    @Environment(\.dismiss) private var dismiss

    @State private var enabledIds:    Set<UUID>     = []
    @State private var rates:         [UUID: String] = [:]
    @State private var confirmed:     Bool           = false
    @State private var pitch:         String         = ""
    @State private var photos:        [String]       = []
    @State private var wasActiveOnLoad: Bool         = false

    @FocusState private var focusedId: UUID?

    private var canSave: Bool {
        guard !enabledIds.isEmpty, confirmed else { return false }
        return enabledIds.allSatisfy { id in
            guard let text = rates[id], let v = Double(text) else { return false }
            return v > 0
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    groupHeader
                        .padding(.bottom, 20)

                    // Tasks
                    VStack(alignment: .leading, spacing: 0) {
                        sectionLabel("Tasks")
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)

                        VStack(spacing: 0) {
                            ForEach(Array(group.offerings.enumerated()), id: \.element.id) { idx, offering in
                                taskRow(offering)
                                if idx < group.offerings.count - 1 {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)

                    // Experience Pitch & Portfolio
                    VStack(alignment: .leading, spacing: 0) {
                        sectionLabel("Experience & Portfolio")
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)

                        bioPortfolioCard
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 24)

                    // Disclaimer
                    disclaimerCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    // Action buttons
                    buttonSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .contentShape(Rectangle())
        .onTapGesture { focusedId = nil }
        .navigationTitle(group.groupName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
        .onAppear { loadState() }
    }

    // MARK: - Group Header

    @ViewBuilder
    private var groupHeader: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageName = group.imageName, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } else {
                Rectangle()
                    .fill(Color.appCard)
                    .frame(height: 160)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.groupName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("\(group.offerings.count) task\(group.offerings.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(16)
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    // MARK: - Task Row

    @ViewBuilder
    private func taskRow(_ offering: ServiceOffering) -> some View {
        let isOn = enabledIds.contains(offering.id)

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Toggle("", isOn: Binding(
                    get: { enabledIds.contains(offering.id) },
                    set: { on in
                        focusedId = nil
                        if on { enabledIds.insert(offering.id) }
                        else  { enabledIds.remove(offering.id); rates.removeValue(forKey: offering.id) }
                    }
                ))
                .labelsHidden()
                .tint(Color.varefyProCyan)

                Text(offering.name)
                    .font(.subheadline)
                    .foregroundStyle(isOn ? .primary : .secondary)

                Spacer()

                if isOn, let text = rates[offering.id], let v = Double(text), v > 0 {
                    Text("$\(String(format: "%.0f", v))/hr")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if isOn {
                HStack(spacing: 8) {
                    Text("$")
                        .fontWeight(.bold)
                        .foregroundStyle(Color.varefyProCyan)
                    TextField("Rate", text: Binding(
                        get: { rates[offering.id] ?? "" },
                        set: { rates[offering.id] = $0 }
                    ))
                    .keyboardType(.decimalPad)
                    .focused($focusedId, equals: offering.id)
                    Text("/ hr")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if rates[offering.id]?.isEmpty ?? true {
                        Text("Enter your rate")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isOn)
    }

    // MARK: - Bio & Portfolio Card

    @ViewBuilder
    private var bioPortfolioCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Pitch editor
            ZStack(alignment: .topLeading) {
                if pitch.isEmpty {
                    Text("Describe your experience with \(group.groupName) — how long you've been doing it, what you specialize in, and what clients can expect...")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $pitch)
                    .font(.subheadline)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if pitch.count > 250 {
                Text("\(pitch.count) / 300")
                    .font(.caption2)
                    .foregroundStyle(pitch.count > 300 ? .red : .secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Portfolio photos
            HStack {
                Label("Portfolio Photos", systemImage: "photo.stack")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(photos.count) / 6")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { idx, name in
                        ZStack(alignment: .topTrailing) {
                            if let uiImage = UIImage(named: name) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.appBackground)
                                    .frame(width: 80, height: 80)
                            }
                            Button {
                                focusedId = nil
                                photos.remove(at: idx)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.black.opacity(0.6))
                                    .offset(x: 5, y: -5)
                            }
                        }
                    }

                    if photos.count < 6 {
                        Button {
                            focusedId = nil
                            let pool = GroupProfile.dummyPool
                            let next = pool.first { !photos.contains($0) }
                                     ?? pool[photos.count % pool.count]
                            photos.append(next)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundStyle(Color.varefyProCyan)
                                Text("Add Photo")
                                    .font(.caption2)
                                    .foregroundStyle(Color.varefyProCyan)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color.varefyProCyan.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.varefyProCyan.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Disclaimer Card

    @ViewBuilder
    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                confirmed.toggle()
                focusedId = nil
            } label: {
                Image(systemName: confirmed ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundStyle(confirmed ? Color.varefyProCyan : Color(red: 0.55, green: 0.45, blue: 0.20))
            }
            .buttonStyle(.plain)

            Text("By selecting this service category, you represent and warrant that you possess the skills, experience, tools, and licenses necessary to perform the services associated with this category.")
                .font(.caption)
                .foregroundStyle(Color(red: 0.35, green: 0.28, blue: 0.10))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(red: 0.98, green: 0.95, blue: 0.84))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.80, green: 0.72, blue: 0.50), lineWidth: 1))
    }

    // MARK: - Button Section

    @ViewBuilder
    private var buttonSection: some View {
        VStack(spacing: 12) {
            Button {
                save()
                dismiss()
            } label: {
                Text(wasActiveOnLoad ? "Save Changes" : "Enable \(group.groupName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(canSave ? .black : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSave ? Color.varefyProCyan : Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSave)

            if wasActiveOnLoad {
                Button(role: .destructive) {
                    disableGroup()
                    dismiss()
                } label: {
                    Text("Disable \(group.groupName)")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Section Label

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    // MARK: - Helpers

    private func loadState() {
        wasActiveOnLoad = group.offerings.contains { $0.isEnabled }
        enabledIds = Set(group.offerings.filter { $0.isEnabled }.map { $0.id })
        confirmed = servicesVM.toolsConfirmed(forGroup: group.groupName)
        for offering in group.offerings {
            if let rate = offering.hourlyRate {
                rates[offering.id] = String(format: "%.0f", rate)
            }
        }
        let profile = servicesVM.profile(for: group.groupName)
        if !profile.pitch.isEmpty { pitch = profile.pitch }
        if !profile.portfolioImageNames.isEmpty { photos = profile.portfolioImageNames }
    }

    private func save() {
        for offering in group.offerings {
            if enabledIds.contains(offering.id) {
                let rate = Double(rates[offering.id] ?? "") ?? 0
                servicesVM.setEnabled(true, for: offering.id)
                servicesVM.setRate(rate, for: offering.id)
                servicesVM.setToolsConfirmed(confirmed, for: offering.id)
            } else {
                servicesVM.setEnabled(false, for: offering.id)
            }
        }
        servicesVM.updatePitch(pitch, for: group.groupName)
        servicesVM.groupProfiles[group.groupName, default: GroupProfile(pitch: "", portfolioImageNames: [])].portfolioImageNames = photos
    }

    private func disableGroup() {
        for offering in group.offerings {
            servicesVM.setEnabled(false, for: offering.id)
            servicesVM.setToolsConfirmed(false, for: offering.id)
        }
    }
}
