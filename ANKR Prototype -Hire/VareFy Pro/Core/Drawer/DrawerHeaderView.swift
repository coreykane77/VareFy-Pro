import SwiftUI

struct DrawerHeaderView: View {
    let profile: UserProfile
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    if let uiImage = UIImage(named: "Marcus") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.varefyProCyan.opacity(0.4), lineWidth: 2))
                    } else {
                        Circle()
                            .fill(Color.varefyProCyan.opacity(0.2))
                            .frame(width: 72, height: 72)
                        Text(profile.initials)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                }

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(profile.fullName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if profile.isBoss { BOSSBadge() }
                    }
                    Text(profile.businessName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Color.varefyProGold)
                        Text(String(format: "%.1f", profile.rating))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 4) {
                    Text("View Profile")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(Color.appCard)
        }
        .buttonStyle(.highlightRow)
    }
}
