import SwiftUI

enum WorkOrderStatus: String, CaseIterable, Equatable {
    case pending         = "Pending"
    case readyToNavigate = "Ready"
    case enRoute         = "En Route"
    case arrived         = "Arrived"
    case preWork         = "Pre Work"
    case activeBilling   = "Active"
    case paused          = "Paused"
    case postWork        = "Post Work"
    case clientReview    = "Review"

    var displayName: String { rawValue }

    /// Lower number = higher in the list
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
        }
    }
}
