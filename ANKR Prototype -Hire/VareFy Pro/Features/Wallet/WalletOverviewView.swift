import SwiftUI

struct WalletOverviewView: View {
    @Environment(WalletViewModel.self) private var walletVM

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Balance card
                    balanceCard

                    // Recent transactions
                    transactionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Wallet")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }

    private var balanceCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("AVAILABLE BALANCE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                Text(walletVM.balance.formattedAsCurrency())
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(.primary)
            }

            NavigationLink(value: NavRoute.managePayout) {
                Text("Manage")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.varefyProCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.highlightRow)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.varefyProCyan.opacity(0.25), Color.varefyProCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT TRANSACTIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)

            VStack(spacing: 0) {
                ForEach(walletVM.transactions) { tx in
                    txRow(tx)
                    if tx.id != walletVM.transactions.last?.id {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func txRow(_ tx: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(tx.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text(tx.date.formattedAsDate())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(tx.amount >= 0 ? "+\(tx.amount.formattedAsCurrency())" : tx.amount.formattedAsCurrency())
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(tx.amount >= 0 ? Color.varefyProCyan : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
