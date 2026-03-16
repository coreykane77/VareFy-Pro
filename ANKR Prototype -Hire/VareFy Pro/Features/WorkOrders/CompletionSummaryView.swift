import SwiftUI
import UIKit

struct CompletionSummaryView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @State private var showReportIssue = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let order = order {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection(order)
                        laborSection(order)
                        materialsSection(order)
                        timelineSection(order)
                        proofOfWorkSection(order)
                        totalSummarySection(order)

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
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            } else {
                Text("Work order unavailable.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Work Order Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .sheet(isPresented: $showReportIssue) {
            ReportIssueSheet(orderId: orderId)
                .environment(workOrderVM)
        }
        .closeButton()
    }

    // MARK: - Header

    @ViewBuilder
    private func headerSection(_ order: WorkOrder) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Work Order")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(order.id.uuidString.prefix(8).uppercased())
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fontDesign(.monospaced)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.varefyProCyan)
                    Text("Verified")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.varefyProCyan.opacity(0.15))
                .clipShape(Capsule())
            }

            Divider().background(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.varefyProCyan.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(order.clientInitials)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.varefyProCyan)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.clientName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(order.serviceTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(order.scheduledTime.formattedAsDate())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
            VStack(spacing: 10) {
                if order.materialItems.isEmpty {
                    Text("No materials logged")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                        Text("Materials Total")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(order.materialsTotal.formattedAsCurrency())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                }
            }
        }
    }

    // MARK: - Timeline

    @ViewBuilder
    private func timelineSection(_ order: WorkOrder) -> some View {
        sectionCard(title: "VERIFIED TIMELINE") {
            VStack(spacing: 0) {
                ForEach(order.timelineEvents) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.type.iconName)
                            .font(.body)
                            .foregroundStyle(Color.varefyProCyan)
                            .frame(width: 24)
                        Text(event.type.label)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(event.timestamp.formattedAsTime())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    if event.id != order.timelineEvents.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
                if order.timelineEvents.isEmpty {
                    Text("No timeline events recorded.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Proof of Work

    @ViewBuilder
    private func proofOfWorkSection(_ order: WorkOrder) -> some View {
        sectionCard(title: "PROOF OF WORK") {
            VStack(alignment: .leading, spacing: 16) {
                photoRow(title: "Before Work", photos: order.prePhotos, met: order.prePhotoCount >= Constants.minPhotosRequired)
                Divider().background(Color.white.opacity(0.1))
                photoRow(title: "After Completion", photos: order.postPhotos, met: order.postPhotoCount >= Constants.minPhotosRequired)
            }
        }
    }

    @ViewBuilder
    private func photoRow(title: String, photos: [UIImage], met: Bool) -> some View {
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
            if photos.isEmpty {
                Text("No photos recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { _, photo in
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFill()
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
            summaryRow(label: "Total Paid", value: order.totalPaid.formattedAsCurrency(), valueColor: .white, bold: true)
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
