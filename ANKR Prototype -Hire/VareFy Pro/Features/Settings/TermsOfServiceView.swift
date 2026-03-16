import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Last updated: January 1, 2026")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    legalSection("1. Acceptance of Terms") {
                        "By accessing or using VareFy Pro, you agree to be bound by these Terms of Service. If you do not agree, you may not use the platform. VareFy Pro reserves the right to update these terms at any time with notice provided through the app."
                    }

                    legalSection("2. Platform Overview") {
                        "VareFy Pro is an integrity-first service marketplace that connects verified service professionals (Hires) with clients seeking skilled labor. VareFy Pro does not employ Hires and is not responsible for the quality, safety, or legality of services performed."
                    }

                    legalSection("3. Hire Eligibility") {
                        "To register as a Hire on VareFy Pro, you must be at least 18 years of age, provide accurate identity and service information, and comply with all applicable local, state, and federal licensing requirements for the services you offer."
                    }

                    legalSection("4. Work Orders and Billing") {
                        "Billing begins only when a Hire presses Start Work. All work sessions are time-tracked and photo-verified. VareFy Pro processes payments on behalf of clients and disburses earnings to Hires following client review. VareFy Pro charges a platform service fee on each completed transaction."
                    }

                    legalSection("5. Integrity Requirements") {
                        "Hires agree to complete pre-work and post-work photo documentation for every job. Falsifying, deleting, or withholding required photos may result in account suspension. Location integrity monitoring may be used to validate on-site time."
                    }

                    legalSection("6. Boss Tier Subscription") {
                        "Boss Plan subscriptions are billed monthly at the rate shown at time of purchase. Subscriptions auto-renew unless cancelled at least 24 hours before the renewal date through the App Store. VareFy Pro does not process subscription cancellations directly."
                    }

                    legalSection("7. Prohibited Conduct") {
                        "You may not use VareFy Pro to engage in fraudulent activity, misrepresent your services or identity, harass or harm other users, or circumvent the platform to conduct off-platform transactions with clients sourced through VareFy Pro."
                    }

                    legalSection("8. Limitation of Liability") {
                        "VareFy Pro is provided on an \"as is\" basis. To the maximum extent permitted by law, VareFy Pro disclaims all warranties and shall not be liable for indirect, incidental, or consequential damages arising from your use of the platform."
                    }

                    legalSection("9. Governing Law") {
                        "These Terms are governed by the laws of the State of Texas. Any disputes shall be resolved through binding arbitration in accordance with the rules of the American Arbitration Association."
                    }

                    legalSection("10. Contact") {
                        "For questions regarding these Terms, contact us at legal@varefy.app."
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Terms of Service")
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
