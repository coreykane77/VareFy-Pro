import SwiftUI

struct BannerWarningView: View {
    let message: String
    var countdown: Int? = nil
    var onStillHere: (() -> Void)? = nil
    var onLargeProperty: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            if onStillHere != nil || onLargeProperty != nil {
                HStack(spacing: 8) {
                    if let action = onStillHere {
                        Button(action: action) {
                            Text("I'm Still Here")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color.black.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    if let action = onLargeProperty {
                        Button(action: action) {
                            Text("Large Property")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Color.black.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.varefyProGold)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
