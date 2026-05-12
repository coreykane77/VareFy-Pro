import Foundation

enum EstimateStatus: String, Codable {
    case pending, accepted, declined, expired
}

struct Estimate: Identifiable {
    let id: UUID
    let workOrderId: UUID
    var estimatedHours: Double
    var estimatedMaterials: Double
    var estimatedTotal: Double
    var proposedStartDate: Date
    var materialsDepositEnabled: Bool
    var materialsDepositAmount: Double
    var status: EstimateStatus
    var createdAt: Date?
}
