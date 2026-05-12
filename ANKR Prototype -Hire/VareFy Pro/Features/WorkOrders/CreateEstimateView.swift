import SwiftUI

struct CreateEstimateView: View {
    let orderId: UUID
    let onSent: () -> Void

    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(\.dismiss) private var dismiss

    @State private var estimatedHoursText = ""
    @State private var estimatedMaterialsText = ""
    @State private var proposedStartDate: Date = defaultStartDate()
    @State private var depositEnabled = false
    @State private var depositAmountText = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?
    enum Field { case hours, materials, deposit }

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }
    private var hourlyRate: Double { order?.hourlyRate ?? 0 }
    private var estimatedHours: Double { Double(estimatedHoursText) ?? 0 }
    private var estimatedMaterials: Double { Double(estimatedMaterialsText) ?? 0 }
    private var depositAmount: Double { Double(depositAmountText) ?? 0 }
    private var estimatedTotal: Double { (estimatedHours * hourlyRate) + estimatedMaterials }

    private var canSend: Bool {
        estimatedHours > 0 &&
        proposedStartDate > Date() &&
        (!depositEnabled || depositAmount > 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            contextBanner
                            scopeCard
                            totalCard
                            scheduleCard
                            depositCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                    .scrollDismissesKeyboard(.interactively)

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

    // MARK: - Scope

    private var scopeCard: some View {
        sectionCard(title: "SCOPE") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ESTIMATED HOURS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                    HStack {
                        TextField("0.0", text: $estimatedHoursText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .hours)
                        Spacer()
                        Text("hrs")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider().background(Color.white.opacity(0.08))

                VStack(alignment: .leading, spacing: 8) {
                    Text("ESTIMATED MATERIALS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
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
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(estimatedHours > 0 ? Color.varefyProCyan : .secondary)
                    Text("\(hourlyRate.formattedAsCurrency())/hr × \(String(format: "%.1f", estimatedHours)) hrs + materials")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Schedule

    private var scheduleCard: some View {
        sectionCard(title: "PROPOSED START DATE") {
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

    // MARK: - Deposit

    private var depositCard: some View {
        sectionCard(title: "MATERIALS ADVANCE") {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Request Advance")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text("Client deposits before work begins")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $depositEnabled)
                        .labelsHidden()
                        .tint(Color.varefyProCyan)
                }

                if depositEnabled {
                    Divider().background(Color.white.opacity(0.08))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DEPOSIT AMOUNT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(0.8)
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $depositAmountText)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .deposit)
                        }
                        .padding(14)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let msg = errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }

            PrimaryButton(title: isSending ? "Sending..." : "Send Estimate to Client",
                          isEnabled: canSend && !isSending) {
                Haptics.medium()
                Task { await sendEstimate() }
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(14)
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
                estimatedHours: estimatedHours,
                estimatedMaterials: estimatedMaterials,
                proposedStartDate: proposedStartDate,
                materialsDepositEnabled: depositEnabled,
                materialsDepositAmount: depositAmount
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
                .font(.caption)
                .fontWeight(.heavy)
                .foregroundStyle(.secondary)
                .tracking(1.2)
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
