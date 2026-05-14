import SwiftUI

struct CreateEstimateView: View {
    let orderId: UUID
    let onSent: () -> Void

    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(\.dismiss) private var dismiss

    @State private var estimateTitle = ""
    @State private var estimateDescription = ""
    @State private var estimatedHoursText = ""
    @State private var estimatedMaterialsText = ""
    @State private var startImmediately: Bool = false
    @State private var proposedStartDate: Date = defaultStartDate()
    @State private var validForDays = 30
    @State private var isSending = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?
    enum Field { case title, description, hours, materials }

    private let validityOptions = [7, 14, 30, 60]

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }
    private var hourlyRate: Double { order?.hourlyRate ?? 0 }
    private var estimatedHours: Double { Double(estimatedHoursText) ?? 0 }
    private var estimatedMaterials: Double { Double(estimatedMaterialsText) ?? 0 }
    private var estimatedTotal: Double { (estimatedHours * hourlyRate) + estimatedMaterials }

    private var canSend: Bool {
        !estimateTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        estimatedHours > 0 &&
        !estimatedMaterialsText.trimmingCharacters(in: .whitespaces).isEmpty &&
        (startImmediately || proposedStartDate > Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        contextBanner
                        titleCard
                        scopeCard
                        totalCard
                        scheduleCard
                        validityCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    bottomBar
                }
            }
            .navigationTitle("Create Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }

    // MARK: - Context Banner

    private var contextBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.title3)
                .foregroundStyle(Color.varefyProCyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("Follow-On Estimate")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Timer keeps running. This appointment closes and pays normally regardless of the client's response.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Title & Description

    private var titleCard: some View {
        sectionCard(title: "ESTIMATE DETAILS") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TITLE")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary).tracking(0.8)
                    TextField("e.g. Kitchen Remodel — Cabinets & Flooring", text: $estimateTitle)
                        .focused($focusedField, equals: .title)
                        .padding(14)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider().background(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 8) {
                    Text("SCOPE OF WORK")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary).tracking(0.8)
                    TextField("Describe what's included in this estimate…",
                              text: $estimateDescription, axis: .vertical)
                        .focused($focusedField, equals: .description)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Scope (hours + materials)

    private var scopeCard: some View {
        sectionCard(title: "PRICING") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ESTIMATED HOURS")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary).tracking(0.8)
                    HStack {
                        TextField("0.0", text: $estimatedHoursText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .hours)
                        Spacer()
                        Text("hrs")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider().background(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ESTIMATED MATERIALS")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(.secondary).tracking(0.8)
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0.00", text: $estimatedMaterialsText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .materials)
                    }
                    .padding(14)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Total

    private var totalCard: some View {
        sectionCard(title: "ESTIMATED TOTAL") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(estimatedTotal.formattedAsCurrency())
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(estimatedHours > 0 ? Color.varefyProCyan : .secondary)
                    Text("\(hourlyRate.formattedAsCurrency())/hr × \(String(format: "%.1f", estimatedHours)) hrs + materials")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Schedule

    private var scheduleCard: some View {
        sectionCard(title: "PROPOSED START DATE") {
            VStack(alignment: .leading, spacing: 14) {
                // Immediate / Schedule picker
                HStack(spacing: 8) {
                    startOptionPill(label: "Immediate", icon: "bolt.fill", selected: startImmediately) {
                        Haptics.selection()
                        startImmediately = true
                    }
                    startOptionPill(label: "Schedule Date", icon: "calendar", selected: !startImmediately) {
                        Haptics.selection()
                        startImmediately = false
                    }
                }

                if startImmediately {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.caption).foregroundStyle(Color.varefyProCyan)
                        Text("Work can begin as soon as the client accepts.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    DatePicker(
                        "",
                        selection: $proposedStartDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(Color.varefyProCyan)
                    .labelsHidden()
                }
            }
        }
    }

    private func startOptionPill(label: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption).fontWeight(.semibold)
                Text(label)
                    .font(.subheadline).fontWeight(.semibold)
            }
            .foregroundStyle(selected ? .black : .primary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(selected ? Color.varefyProCyan : Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Validity

    private var validityCard: some View {
        sectionCard(title: "VALID FOR") {
            VStack(spacing: 8) {
                Picker("Valid for", selection: $validForDays) {
                    ForEach(validityOptions, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .clipped()

                let expiresAt = Calendar.current.date(byAdding: .day, value: validForDays, to: Date()) ?? Date()
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill").font(.caption2).foregroundStyle(.secondary)
                    Text("Offer expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let msg = errorMessage {
                Text(msg)
                    .font(.caption).foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }

            PrimaryButton(title: isSending ? "Sending…" : "Send Estimate to Client",
                          isEnabled: canSend && !isSending) {
                Haptics.medium()
                Task { await sendEstimate() }
            }

            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(14)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Color.appBackground)
    }

    // MARK: - Submit

    private func sendEstimate() async {
        isSending = true
        errorMessage = nil
        do {
            try await workOrderVM.createEstimate(
                for: orderId,
                title: estimateTitle.trimmingCharacters(in: .whitespaces),
                description: estimateDescription.trimmingCharacters(in: .whitespaces),
                validForDays: validForDays,
                estimatedHours: estimatedHours,
                estimatedMaterials: estimatedMaterials,
                proposedStartDate: startImmediately ? Date() : proposedStartDate
            )
            onSent()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSending = false
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption).fontWeight(.heavy)
                .foregroundStyle(.secondary).tracking(1.2)
            content()
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private static func defaultStartDate() -> Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}
