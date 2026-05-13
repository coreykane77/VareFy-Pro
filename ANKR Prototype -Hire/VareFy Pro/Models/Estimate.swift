import Foundation

enum EstimateStatus: String, Codable {
    case pending, accepted, declined, expired
}

struct Estimate: Identifiable {
    let id: UUID
    let workOrderId: UUID
    var title: String?
    var description: String?
    var validForDays: Int
    var estimatedHours: Double
    var estimatedMaterials: Double
    var estimatedTotal: Double
    var proposedStartDate: Date
    var status: EstimateStatus
    var createdAt: Date?
}
