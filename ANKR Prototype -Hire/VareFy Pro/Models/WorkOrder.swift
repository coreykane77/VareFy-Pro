import Foundation
import UIKit

struct MaterialLineItem: Identifiable {
    let id: UUID
    var description: String
    var amount: Double

    init(id: UUID = UUID(), description: String = "", amount: Double = 0) {
        self.id = id
        self.description = description
        self.amount = amount
    }
}

struct WorkOrder: Identifiable {
    let id: UUID
    var clientName: String
    var clientInitials: String
    var serviceTitle: String
    var address: String
    var scheduledTime: Date
    var status: WorkOrderStatus
    var clientNotes: String
    var serviceId: String
    var hourlyRate: Double
    var materialItems: [MaterialLineItem]
    var timelineEvents: [TimelineEvent]
    var prePhotos: [UIImage]
    var postPhotos: [UIImage]
    var billingStartTime: Date?
    var elapsedBillingSeconds: Double
    var radiusExpanded: Bool
    var pausedReturnStatus: WorkOrderStatus?

    var laborTotal: Double {
        (elapsedBillingSeconds / 3600.0) * hourlyRate
    }

    var materialsTotal: Double {
        materialItems.reduce(0) { $0 + $1.amount }
    }

    var totalPaid: Double {
        laborTotal + materialsTotal
    }

    var prePhotoCount: Int { prePhotos.count }
    var postPhotoCount: Int { postPhotos.count }

    mutating func addTimelineEvent(_ type: EventType) {
        timelineEvents.append(TimelineEvent(type: type, timestamp: Date()))
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let type: EventType
    let timestamp: Date
}

enum EventType {
    case confirmed
    case arrived
    case radiusExpanded
    case started
    case paused
    case autoPause
    case resumed
    case completed

    var label: String {
        switch self {
        case .confirmed:       return "Job Confirmed"
        case .arrived:         return "Arrived (GPS)"
        case .radiusExpanded:  return "Radius Expanded"
        case .started:         return "Started Work"
        case .paused:          return "Paused"
        case .autoPause:       return "Auto Paused (Left Radius)"
        case .resumed:         return "Resumed"
        case .completed:       return "Completed"
        }
    }

    var iconName: String {
        switch self {
        case .confirmed:       return "checkmark.circle.fill"
        case .arrived:         return "location.fill"
        case .radiusExpanded:  return "arrow.up.left.and.arrow.down.right.circle.fill"
        case .started:         return "play.fill"
        case .paused:          return "pause.fill"
        case .autoPause:       return "exclamationmark.triangle.fill"
        case .resumed:         return "play.circle.fill"
        case .completed:       return "flag.checkered"
        }
    }
}
