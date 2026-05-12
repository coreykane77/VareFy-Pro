import SwiftUI

enum WorkOrderStatus: String, CaseIterable, Equatable, Codable {
    case pending         = "pending"
    case readyToNavigate = "ready_to_navigate"
    case enRoute         = "en_route"
    case arrived         = "arrived"
    case preWork         = "pre_work"
    case activeBilling   = "active_billing"
    case paused          = "paused"
    case postWork        = "post_work"
    case clientReview    = "client_review"
    case completed       = "completed"
    case disputed        = "disputed"
    case cancelled       = "cancelled"

    var displayName: String {
        switch self {
        case .pending:          return "Pending"
        case .readyToNavigate:  return "Ready"
        case .enRoute:          return "En Route"
        case .arrived:          return "Arrived"
        case .preWork:          return "Pre Work"
        case .activeBilling:    return "Active"
        case .paused:           return "Paused"
        case .postWork:         return "Post Work"
        case .clientReview:     return "Review"
        case .completed:        return "Completed"
        case .disputed:         return "Disputed"
        case .cancelled:        return "Cancelled"
        }
    }

    var sortPriority: Int {
        switch self {
        case .activeBilling:    return 0
        case .paused:           return 1
        case .postWork:         return 2
        case .preWork:          return 3
        case .arrived:          return 4
        case .enRoute:          return 5
        case .readyToNavigate:  return 6
        case .pending:          return 7
        case .clientReview:     return 8
        case .completed:        return 9
        case .disputed:         return 10
        case .cancelled:        return 11
        }
    }

    var pillIcon: String {
        switch self {
        case .pending:          return "clock.fill"
        case .readyToNavigate:  return "arrow.triangle.turn.up.right.circle.fill"
        case .enRoute:          return "car.fill"
        case .arrived:          return "location.fill"
        case .preWork:          return "camera.fill"
        case .activeBilling:    return "bolt.fill"
        case .paused:           return "pause.fill"
        case .postWork:         return "camera.fill"
        case .clientReview:     return "checkmark.circle.fill"
        case .completed:        return "checkmark.seal.fill"
        case .disputed:         return "exclamationmark.triangle.fill"
        case .cancelled:        return "xmark.circle.fill"
        }
    }

    var pillColor: Color {
        switch self {
        case .pending:          return .orange
        case .readyToNavigate:  return .blue
        case .enRoute:          return .blue
        case .arrived:          return .green
        case .preWork:          return .yellow
        case .activeBilling:    return Color.varefyProCyan
        case .paused:           return .orange
        case .postWork:         return .yellow
        case .clientReview:     return .green
        case .completed:        return .gray
        case .disputed:         return .red
        case .cancelled:        return .gray
        }
    }
}
