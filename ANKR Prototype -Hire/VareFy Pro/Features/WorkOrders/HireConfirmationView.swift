import SwiftUI

struct HireConfirmationView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(\.dismiss) private var dismiss
    @State private var showReportIssue = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let order = order {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Hero
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 56))
                                    .foregroundStyle(Color.varefyProCyan)
                                Text("You're hired!")
                                    .font(.largeTitle)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(.primary)
                                Text("Review job details to confirm")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 24)

                            // Job detail card
                            VStack(spacing: 0) {
                                confirmRow(label: "Service", value: order.serviceTitle)
                                Divider().background(Color.white.opacity(0.1))
                                confirmRow(label: "Client", value: order.clientName)
                                Divider().background(Color.white.opacity(0.1))
                                confirmRow(label: "Address", value: order.address)
                                Divider().background(Color.white.opacity(0.1))
                                confirmRow(label: "Scheduled", value: order.scheduledTime.formattedAsTime())
                                Divider().background(Color.white.opacity(0.1))
                                confirmRow(label: "Rate", value: "\(order.hourlyRate.formattedAsCurrency())/hr")
                            }
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 16)
                    }

                    // CTA
                    VStack(spacing: 12) {
                        PrimaryButton(
                            title: "Confirm Job",
                            isEnabled: order.status == .pending
                        ) {
                            Task { await workOrderVM.confirmJob(for: orderId) }
                            dismiss()
                        }

                        Button {
                            Haptics.medium()
                            showReportIssue = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                                Text("Report an Issue")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, Constants.bottomBarHeight + 24)
                    .background(Color.appBackground)
                }
            }
        }
        .navigationTitle("Job Confirmation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .sheet(isPresented: $showReportIssue) {
            ReportIssueSheet(orderId: orderId)
                .environment(workOrderVM)
        }
        .closeButton()
    }

    @ViewBuilder
    private func confirmRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
