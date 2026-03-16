import SwiftUI

struct ActiveBillingView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(WalletViewModel.self) private var walletVM

    @State private var navigateToPostWork = false
    @State private var showMaterialsSheet  = false
    @State private var showReportIssue = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let order = order {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            if !workOrderVM.isInsideRadius && order.status == .activeBilling {
                                BannerWarningView(
                                    message: "You've left the job area. Pause or complete your work order.",
                                    countdown: workOrderVM.radiusCountdownSeconds > 0
                                        ? workOrderVM.radiusCountdownSeconds : nil
                                )
                            }
                            timerCard(order)
                            radiusToggle(order)
                            materialsCard(order)
                            earningsCard(order)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }

                    VStack(spacing: 12) {
                        if order.status == .activeBilling {
                            Button {
                                Haptics.medium()
                                workOrderVM.pauseWork(for: orderId)
                            } label: {
                                Label("Pause Work", systemImage: "pause.fill")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.appCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            PrimaryButton(title: "Complete Work") {
                                workOrderVM.moveToPostWork(for: orderId)
                            }
                        } else if order.status == .paused {
                            Button {
                                Haptics.medium()
                                workOrderVM.resumeWork(for: orderId)
                            } label: {
                                Label("Resume Work", systemImage: "play.fill")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.varefyProCyan)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
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
        .navigationTitle("Active Job")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .sheet(isPresented: $showReportIssue) {
            ReportIssueSheet(orderId: orderId)
                .environment(workOrderVM)
        }
        .closeButton()
        .navigationDestination(isPresented: $navigateToPostWork) {
            PostWorkPhotoView(orderId: orderId)
        }
        .onChange(of: workOrderVM.order(id: orderId)?.status) { _, newStatus in
            if newStatus == .postWork {
                Haptics.light()
                navigateToPostWork = true
            }
        }
        .sheet(isPresented: $showMaterialsSheet) {
            if let idx = workOrderVM.index(of: orderId) {
                MaterialsWorksheetView(items: Binding(
                    get: { workOrderVM.workOrders[idx].materialItems },
                    set: { workOrderVM.workOrders[idx].materialItems = $0 }
                ))
            }
        }
    }

    // MARK: - Timer Card

    @ViewBuilder
    private func timerCard(_ order: WorkOrder) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ELAPSED TIME")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                    Text(order.elapsedBillingSeconds.formattedAsElapsed())
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(order.status == .paused ? .orange : Color.varefyProCyan)
                }
                Spacer()
                Circle()
                    .fill(order.status == .activeBilling ? Color.green : .orange)
                    .frame(width: 12, height: 12)
                    .scaleEffect(order.status == .activeBilling ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                               value: order.status)
            }
            if order.status == .paused {
                Text("PAUSED")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Radius Toggle

    @ViewBuilder
    private func radiusToggle(_ order: WorkOrder) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LOCATION SIMULATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
            HStack(spacing: 0) {
                radiusToggleButton(label: "Inside Radius", isSelected: workOrderVM.isInsideRadius) {
                    workOrderVM.setInsideRadius()
                }
                radiusToggleButton(label: "Outside Radius", isSelected: !workOrderVM.isInsideRadius) {
                    workOrderVM.setOutsideRadius(for: orderId)
                }
            }
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func radiusToggleButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.selection(); action() }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? (label.contains("Inside") ? Color.green : Color.red) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Materials Card

    @ViewBuilder
    private func materialsCard(_ order: WorkOrder) -> some View {
        Button {
            Haptics.light()
            showMaterialsSheet = true
        } label: {
            VStack(spacing: 10) {
                HStack {
                    Text("MATERIALS & SUPPLIES")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                    Spacer()
                    Image(systemName: order.materialItems.isEmpty ? "plus.circle" : "pencil.circle")
                        .foregroundStyle(Color.varefyProCyan)
                        .font(.subheadline)
                }

                if order.materialItems.isEmpty {
                    HStack {
                        Text("Tap to add items")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("$0.00")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(order.materialItems) { item in
                        HStack {
                            Text(item.description.isEmpty ? "—" : item.description)
                                .font(.subheadline)
                                .foregroundStyle(item.description.isEmpty ? .secondary : .primary)
                            Spacer()
                            Text(item.amount.formattedAsCurrency())
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                    Divider().background(Color.white.opacity(0.08))
                    HStack {
                        Text("Total")
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                        Spacer()
                        Text(order.materialsTotal.formattedAsCurrency())
                            .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.varefyProCyan)
                    }
                }
            }
            .padding(16)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Earnings Card

    @ViewBuilder
    private func earningsCard(_ order: WorkOrder) -> some View {
        VStack(spacing: 12) {
            earningsRow(label: "Hourly Rate", value: "\(order.hourlyRate.formattedAsCurrency())/hr")
            Divider().background(Color.white.opacity(0.1))
            earningsRow(label: "Labor so far", value: order.laborTotal.formattedAsCurrency(), valueColor: Color.varefyProCyan)
            earningsRow(label: "Materials", value: order.materialsTotal.formattedAsCurrency())
            Divider().background(Color.white.opacity(0.1))
            earningsRow(label: "Total (est.)", value: order.totalPaid.formattedAsCurrency(), valueColor: .white, bold: true)
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func earningsRow(label: String, value: String, valueColor: Color = .gray, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline : .caption)
                .fontWeight(bold ? .semibold : .regular)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(bold ? .headline : .subheadline)
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Materials Worksheet

struct MaterialsWorksheetView: View {
    @Binding var items: [MaterialLineItem]
    @Environment(\.dismiss) private var dismiss

    // Local draft row: id + description + amount as string
    @State private var rows: [DraftRow] = []
    @FocusState private var focusedId: UUID?

    private var total: Double {
        rows.reduce(0) { $0 + (Double($1.amountText) ?? 0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        List {
                            ForEach($rows) { $row in
                                lineRow(row: $row)
                                    .listRowBackground(Color.appCard)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
                            .onDelete { rows.remove(atOffsets: $0) }

                            Button {
                                let r = DraftRow()
                                rows.append(r)
                                focusedId = r.id
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.varefyProCyan)
                                    Text("Add Item")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.varefyProCyan)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.appCard)
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: CGFloat(rows.count + 1) * 56 + 80)

                        // Running total
                        HStack {
                            Text("Total")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(total.formattedAsCurrency())
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.varefyProCyan)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.appBackground)
            .navigationTitle("Materials & Supplies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        items = rows
                            .filter { !$0.description.isEmpty || (Double($0.amountText) ?? 0) > 0 }
                            .map { MaterialLineItem(id: $0.id, description: $0.description, amount: Double($0.amountText) ?? 0) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.varefyProCyan)
                }
            }
            .onAppear {
                rows = items.map { DraftRow(id: $0.id, description: $0.description, amount: $0.amount) }
            }
        }
    }

    @ViewBuilder
    private func lineRow(row: Binding<DraftRow>) -> some View {
        HStack(spacing: 12) {
            TextField("Description", text: row.description)
                .font(.subheadline)
                .focused($focusedId, equals: row.id)

            Spacer()

            HStack(spacing: 2) {
                Text("$")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextField("0.00", text: row.amountText)
                    .font(.subheadline)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 72)
            }
        }
        .padding(.vertical, 10)
    }
}

private struct DraftRow: Identifiable {
    let id: UUID
    var description: String
    var amountText: String

    init(id: UUID = UUID(), description: String = "", amount: Double = 0) {
        self.id = id
        self.description = description
        self.amountText = amount > 0 ? String(format: "%.2f", amount) : ""
    }
}
