import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("VFYX")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                ProgressView()
                    .tint(Color.varefyProCyan)
            }
        }
    }
}
