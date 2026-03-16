import SwiftUI

struct WorkOrderCardView: View {
    let order: WorkOrder

    var body: some View {
        HStack(spacing: 14) {
            // Client initials avatar
            ZStack {
                Circle()
                    .fill(Color.varefyProCyan.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(order.clientInitials)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.varefyProCyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(order.serviceTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                    StatusPillView(status: order.status)
                }
                Text(order.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(order.scheduledTime.formattedAsTime())
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
