import SwiftUI

struct BannerWarningView: View {
    let message: String
    var countdown: Int? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.black)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                if let seconds = countdown, seconds > 0 {
                    Text("Auto-pausing in \(seconds)s")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.7))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.varefyProGold)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
