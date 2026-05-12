import SwiftUI

struct PendingApprovalView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var isCheckingStatus = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image("VFYX")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)

                    VStack(spacing: 8) {
                        Text("Application Under Review")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("Your VareFy Pro account is pending founder approval. You'll have full access once your application is reviewed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        Task { await checkStatus() }
                    } label: {
                        HStack(spacing: 8) {
                            if isCheckingStatus {
                                ProgressView()
                                    .tint(Color.appBackground)
                                    .scaleEffect(0.8)
                            }
                            Text(isCheckingStatus ? "Checking…" : "Check Status")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.varefyProCyan)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isCheckingStatus)

                    Button {
                        Task {
                            try? await authManager.signOut()
                        }
                    } label: {
                        Text("Sign Out")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func checkStatus() async {
        isCheckingStatus = true
        await authManager.fetchProfile()
        isCheckingStatus = false
    }
}
