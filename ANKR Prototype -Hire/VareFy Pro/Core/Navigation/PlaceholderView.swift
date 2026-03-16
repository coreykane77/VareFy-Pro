import SwiftUI

struct PlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.varefyProCyan)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Prototype screen")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Not implemented")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.6))
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }
}
