import SwiftUI

struct ReportIssueSheet: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(\.dismiss) private var dismiss

    private let quickIssues = [
        "Client no-show",
        "Safety concern",
        "Site access problem",
        "Billing / payment dispute",
        "Other"
    ]

    @State private var selectedQuickIssue: String? = nil
    @State private var details: String = ""
    @State private var submitted = false
    @FocusState private var detailsFocused: Bool

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if submitted {
                    submittedState
                } else {
                    reportForm
                }
            }
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                // Auto-pause billing while the pro files a report
                if workOrderVM.order(id: orderId)?.status == .activeBilling {
                    workOrderVM.pauseWork(for: orderId)
                }
            }
        }
    }

    // MARK: - Form

    private var reportForm: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header card
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.varefyProCyan.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.title3)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Integrity Team")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Text("We're here to help resolve any job issue.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Job context
                if let order = order {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("JOB REFERENCE")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .tracking(0.8)
                            Text("\(order.serviceTitle) — \(order.clientName)")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        StatusPillView(status: order.status)
                    }
                    .padding(14)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Quick issue selector
                VStack(alignment: .leading, spacing: 10) {
                    Text("WHAT'S THE ISSUE?")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)

                    VStack(spacing: 0) {
                        ForEach(quickIssues, id: \.self) { issue in
                            Button {
                                Haptics.selection()
                                selectedQuickIssue = issue
                            } label: {
                                HStack {
                                    Text(issue)
                                        .font(.subheadline)
                                        .foregroundStyle(selectedQuickIssue == issue ? Color.varefyProCyan : .primary)
                                    Spacer()
                                    if selectedQuickIssue == issue {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(Color.varefyProCyan)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(selectedQuickIssue == issue
                                    ? Color.varefyProCyan.opacity(0.08)
                                    : Color.appCard)
                            }
                            if issue != quickIssues.last {
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Details field
                VStack(alignment: .leading, spacing: 10) {
                    Text("ADDITIONAL DETAILS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)

                    ZStack(alignment: .topLeading) {
                        if details.isEmpty {
                            Text("Describe what happened…")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 12)
                                .padding(.leading, 14)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $details)
                            .font(.subheadline)
                            .focused($detailsFocused)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Response time note
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Simple issues resolved in 1–4 hrs · Complex cases within 48 hrs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Send button
                Button {
                    Haptics.medium()
                    detailsFocused = false
                    withAnimation(.spring(response: 0.4)) {
                        submitted = true
                    }
                } label: {
                    Text("Send Report")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedQuickIssue != nil ? Color.varefyProCyan : Color.varefyProCyan.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedQuickIssue == nil)
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Submitted State

    private var submittedState: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.varefyProCyan.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.varefyProCyan)
            }

            VStack(spacing: 8) {
                Text("Report Submitted")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(.primary)
                Text("An Integrity agent will review your case and follow up shortly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 0) {
                issueConfirmRow(icon: "tag.fill", label: selectedQuickIssue ?? "")
                Divider().background(Color.white.opacity(0.08)).padding(.leading, 16)
                issueConfirmRow(icon: "clock.fill", label: "Response expected within 4 hrs")
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 8)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.varefyProCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func issueConfirmRow(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.varefyProCyan)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
