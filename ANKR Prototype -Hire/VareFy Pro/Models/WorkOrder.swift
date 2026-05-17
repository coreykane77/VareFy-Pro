import Foundation
import UIKit

struct MaterialLineItem: Identifiable {
    let id: UUID
    var description: String
    var amount: Double
    var receiptPhoto: UIImage?

    init(id: UUID = UUID(), description: String = "", amount: Double = 0, receiptPhoto: UIImage? = nil) {
        self.id = id
        self.description = description
        self.amount = amount
        self.receiptPhoto = receiptPhoto
    }
}

// Represents a photo that has been uploaded to Supabase Storage (or is in-flight).
struct PhotoRecord: Identifiable {
    let id: UUID
    let storagePath: String     // empty string while upload is in-flight
    var localImage: UIImage?    // present immediately after capture; nil after session reload
    var signedURL: URL?         // populated when loaded from Supabase
    var isUploading: Bool       // true until the storage + DB write completes
}

struct WorkOrder: Identifiable {
    let id: UUID
    let clientId: UUID
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
    var prePhotoRecords: [PhotoRecord]
    var postPhotoRecords: [PhotoRecord]
    var billingStartTime: Date?
    var elapsedBillingSeconds: Double
    var radiusExpanded: Bool
    var pausedReturnStatus: WorkOrderStatus?
    var responseDeadline: Date?
    var completedAt: Date?

    var isChatAvailable: Bool {
        switch status {
        case .cancelled: return false
        case .complete:
            guard let completedAt else { return true }
            return Date().timeIntervalSince(completedAt) < 72 * 3600
        default: return true
        }
    }

    var laborTotal: Double {
        (elapsedBillingSeconds / 3600.0) * hourlyRate
    }

    var materialsTotal: Double {
        materialItems.reduce(0) { $0 + $1.amount }
    }

    var totalPaid: Double {
        laborTotal + materialsTotal
    }

    // Count only confirmed (fully uploaded) photos — used by gate checks.
    var confirmedPrePhotoCount: Int { prePhotoRecords.filter { !$0.isUploading }.count }
    var confirmedPostPhotoCount: Int { postPhotoRecords.filter { !$0.isUploading }.count }

    // Total including in-flight — used for the grid display counter.
    var prePhotoCount: Int { prePhotoRecords.count }
    var postPhotoCount: Int { postPhotoRecords.count }

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
