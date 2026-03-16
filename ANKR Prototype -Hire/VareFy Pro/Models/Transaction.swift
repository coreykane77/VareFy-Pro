import Foundation

struct Transaction: Identifiable {
    let id: UUID
    let description: String
    let amount: Double
    let date: Date
    let type: TransactionType

    enum TransactionType {
        case credit
        case debit
        case payout
    }
}
