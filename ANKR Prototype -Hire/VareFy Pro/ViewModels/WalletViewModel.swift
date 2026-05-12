import Foundation
import Observation

@Observable
class WalletViewModel {
    var balance: Double = 530.00
    var transactions: [Transaction] = PreviewData.transactions

    func creditBalance(_ amount: Double, description: String) {
        balance += amount
        let tx = Transaction(
            id: UUID(),
            description: description,
            amount: amount,
            date: Date(),
            type: .credit
        )
        transactions.insert(tx, at: 0)
    }

    func requestPayout(amount: Double, isInstant: Bool) {
        balance -= amount
        let tx = Transaction(
            id: UUID(),
            description: isInstant ? "Instant Pay" : "Bank Transfer",
            amount: -amount,
            date: Date(),
            type: .payout
        )
        transactions.insert(tx, at: 0)
    }
}
