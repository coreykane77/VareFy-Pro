import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Last updated: January 1, 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    legalSection("1. Information We Collect") {
                        "VareFy Pro collects information you provide directly, including your name, email address, phone number, profile photo, service listings, and payment details. We also collect job activity data such as timestamps, location during active work orders, and photo documentation required by our integrity system."
                    }

                    legalSection("2. How We Use Your Information") {
                        "We use your information to operate the VareFy Pro platform, process payments, verify job completion, improve our services, send notifications about your account and work orders, and comply with legal obligations. We do not sell your personal information to third parties."
                    }

                    legalSection("3. Location Data") {
                        "VareFy Pro requests location access during active work orders to support job site verification and radius monitoring. Location data is used solely for integrity purposes and is not stored beyond the active work session. We do not track your location when the app is not in use."
                    }

                    legalSection("4. Photo and Camera Access") {
                        "Camera access is required to upload pre-work and post-work job site photos. Photos are stored securely and associated with your work order record. Photos may be reviewed in the event of a dispute. We do not share your photos with third parties except as required by law."
                    }

                    legalSection("5. Payment Information") {
                        "Payment processing is handled by our third-party payment partner. VareFy Pro does not store full card or bank account numbers on our servers. We retain transaction records for accounting and dispute resolution purposes."
                    }

                    legalSection("6. Data Sharing") {
                        "We may share your information with clients as necessary to fulfill a work order (e.g., your name and service details). We may also share data with service providers who assist in operating our platform, subject to confidentiality agreements."
                    }

                    legalSection("7. Data Retention") {
                        "We retain your account information for as long as your account is active. Work order records, including photos and timelines, are retained for a minimum of 2 years. You may request deletion of your account by contacting support."
                    }

                    legalSection("8. Your Rights") {
                        "Depending on your jurisdiction, you may have the right to access, correct, or delete your personal data. To submit a data request, contact us at privacy@varefy.app. We will respond within 30 days."
                    }

                    legalSection("9. Security") {
                        "VareFy Pro uses industry-standard encryption and security practices to protect your data. However, no system is completely secure. We encourage you to use a strong, unique password and to report any suspicious activity to support immediately."
                    }

                    legalSection("10. Contact") {
                        "For privacy-related inquiries, contact us at privacy@varefy.app or visit VareFy Pro.app."
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }

    @ViewBuilder
    private func legalSection(_ title: String, body: () -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(body())
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
