import SwiftUI

struct StatusPillView: View {
    let status: WorkOrderStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.pillIcon)
                .font(.system(size: 10, weight: .semibold))
            Text(status.displayName)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
        }
        .foregroundStyle(status.pillColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(status.pillColor.opacity(0.15))
        .clipShape(Capsule())
    }
}
