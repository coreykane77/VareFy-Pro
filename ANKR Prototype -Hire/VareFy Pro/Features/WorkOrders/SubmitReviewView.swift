import SwiftUI
import UIKit

struct SubmitReviewView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(WalletViewModel.self) private var walletVM
    @Environment(\.dismiss) private var dismiss

    @State private var showAddMaterial = false
    @State private var showReceiptPicker = false
    @State private var receiptTargetMaterialId: UUID? = nil
    @State private var navigateToCompletion = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let order = order {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            reviewBanner
                            laborSection(order)
                            materialsSection(order)
                            proofOfWorkSection(order)
                            totalSummarySection(order)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }

                    VStack(spacing: 12) {
                        PrimaryButton(title: "Send to Client for Review", isEnabled: true) {
                            Haptics.medium()
                            Task { await workOrderVM.completeWork(for: orderId, walletVM: walletVM) }
                            navigateToCompletion = true
                        }
                        Button {
                            dismiss()
                        } label: {
                            Text("Edit Submission")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.varefyProCyan)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.varefyProCyan.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, Constants.bottomBarHeight + 24)
                    .background(Color.appBackground)
                }
            } else {
                Text("Work order unavailable.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Review & Submit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToCompletion) {
            CompletionSummaryView(orderId: orderId)
        }
        .sheet(isPresented: $showAddMaterial) {
            AddMaterialSheet(orderId: orderId)
                .environment(workOrderVM)
        }
        .sheet(isPresented: $showReceiptPicker) {
            ImagePickerView(selectedImage: Binding(
                get: { nil },
                set: { img in
                    if let img = img, let targetId = receiptTargetMaterialId {
                        workOrderVM.setReceiptPhoto(img, for: targetId, orderId: orderId)
                        receiptTargetMaterialId = nil
                    }
                }
            ))
        }
    }

    // MARK: - Review Banner

    private var reviewBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.varefyProCyan)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Ready to Send")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Review your submission before sending to client")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Labor

    @ViewBuilder
    private func laborSection(_ order: WorkOrder) -> some View {
        sectionCard(title: "LABOR") {
            summaryRow(label: "Time on Site", value: order.elapsedBillingSeconds.formattedAsElapsed())
            Divider().background(Color.white.opacity(0.1))
            summaryRow(label: "Hourly Rate", value: "\(order.hourlyRate.formattedAsCurrency())/hr")
            Divider().background(Color.white.opacity(0.1))
            summaryRow(label: "Labor Total", value: order.laborTotal.formattedAsCurrency(), valueColor: Color.varefyProCyan, bold: true)
        }
    }

    // MARK: - Materials

    @ViewBuilder
    private func materialsSection(_ order: WorkOrder) -> some View {
        sectionCard(title: "MATERIALS & SUPPLIES") {
            VStack(spacing: 12) {
                if !order.materialItems.isEmpty {
                    ForEach(Array(order.materialItems.enumerated()), id: \.element.id) { idx, item in
                        materialRow(item: item, at: idx)
                        if idx < order.materialItems.count - 1 {
                            Divider().background(Color.white.opacity(0.08))
                        }
                    }
                    Divider().background(Color.white.opacity(0.1))
                    summaryRow(label: "Materials Total", value: order.materialsTotal.formattedAsCurrency(), valueColor: Color.varefyProCyan, bold: true)
                }

                Button {
                    showAddMaterial = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.varefyProCyan)
                        Text("Add Material or Supply")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.varefyProCyan.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func materialRow(item: MaterialLineItem, at idx: Int) -> some View {
        HStack(spacing: 10) {
            Button {
                receiptTargetMaterialId = item.id
                showReceiptPicker = true
            } label: {
                if let photo = item.receiptPhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.varefyProCyan.opacity(0.5), lineWidth: 1)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.varefyProCyan.opacity(0.08))
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.varefyProCyan.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3]))
                            )
                        Image(systemName: "receipt")
                            .font(.caption)
                            .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.description.isEmpty ? "—" : item.description)
                    .font(.subheadline)
                    .foregroundStyle(item.description.isEmpty ? .secondary : .primary)
                Text(item.receiptPhoto == nil ? "Tap to attach receipt" : "Receipt attached")
                    .font(.caption2)
                    .foregroundStyle(item.receiptPhoto == nil ? Color.secondary : Color.green)
            }

            Spacer()

            Text(item.amount.formattedAsCurrency())
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Button {
                workOrderVM.removeMaterialItem(at: idx, for: orderId)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Proof of Work

    @ViewBuilder
    private func proofOfWorkSection(_ order: WorkOrder) -> some View {
        sectionCard(title: "PROOF OF WORK") {
            VStack(alignment: .leading, spacing: 16) {
                photoRow(title: "Before Work", records: order.prePhotoRecords, met: order.confirmedPrePhotoCount >= Constants.minPhotosRequired)
                Divider().background(Color.white.opacity(0.1))
                photoRow(title: "After Completion", records: order.postPhotoRecords, met: order.confirmedPostPhotoCount >= Constants.minPhotosRequired)
            }
        }
    }

    @ViewBuilder
    private func photoRow(title: String, records: [PhotoRecord], met: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                if met {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            if records.isEmpty {
                Text("No photos recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(records) { record in
                            Group {
                                if let image = record.localImage {
                                    Image(uiImage: image).resizable().scaledToFill()
                                } else if let url = record.signedURL {
                                    AsyncImage(url: url) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: { Color.appCard }
                                } else {
                                    Color.appCard
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Total Summary

    @ViewBuilder
    private func totalSummarySection(_ order: WorkOrder) -> some View {
        sectionCard(title: "TOTAL SUMMARY") {
            summaryRow(label: "Labor", value: order.laborTotal.formattedAsCurrency())
            Divider().background(Color.white.opacity(0.1))
            summaryRow(label: "Materials & Supplies", value: order.materialsTotal.formattedAsCurrency())
            Divider().background(Color.white.opacity(0.15))
            summaryRow(label: "Total", value: order.totalPaid.formattedAsCurrency(), valueColor: .white, bold: true)
        }
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

    @ViewBuilder
    private func summaryRow(label: String, value: String, valueColor: Color = .gray, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(bold ? .headline : .subheadline)
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Add Material Sheet

struct AddMaterialSheet: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var amountText = ""
    @FocusState private var focusedField: Field?

    enum Field { case description, amount }

    private var amount: Double { Double(amountText) ?? 0 }
    private var canAdd: Bool {
        !description.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(0.8)
                        TextField("e.g. Paint, lumber, supplies...", text: $description)
                            .padding(14)
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($focusedField, equals: .description)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(0.8)
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .amount)
                        }
                        .padding(14)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer()

                    PrimaryButton(title: "Add Item", isEnabled: canAdd) {
                        workOrderVM.addMaterialItem(
                            description: description.trimmingCharacters(in: .whitespaces),
                            amount: amount,
                            for: orderId
                        )
                        dismiss()
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.varefyProCyan)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }
}
