import Foundation
import UIKit

enum PreviewData {

    static let userProfile = UserProfile(
        id: UUID(),
        firstName: "Marcus",
        lastName: "Reid",
        businessName: "Reid Pro Services",
        rating: 4.8,
        isBoss: true,
        hourlyRate: 65.0,
        serviceTitle: "General Labor",
        serviceId: "service-001",
        email: "marcus.reid@reidproservices.com",
        phone: "(817) 555-0142",
        legalAddress: "4821 Ridgecrest Blvd",
        city: "Fort Worth",
        state: "TX",
        zip: "76137",
        country: "United States",
        bio: "Hey — I'm Marcus. Born and raised in Fort Worth, TX. I run Reid Pro Services and specialize in general labor, furniture assembly, and haul-away. I'm a VareFy Pro Boss member — upgraded for more visibility and priority placement, and a higher standard I hold myself to.\n\nI take pride in photo-documenting every job, showing up on time, and leaving the site better than I found it. If I can't handle something safely, I'll tell you. Weekday availability plus most Saturdays.",
        closingMessage: "Thanks for choosing Reid Pro Services. I appreciate your trust — feel free to reach out if you have any questions about the work completed. Looking forward to serving you again.",
        vehicleYear: "2019",
        vehicleMake: "Ford",
        vehicleModel: "F-250 SuperDuty",
        crewMembers: ["Doug P.", "Javier E.", "Arthur M.", "John M."],
        documents: DocumentCategory.allCases.map { ProfileDocument(category: $0) }
    )

    static var workOrders: [WorkOrder] = [
        WorkOrder(
            id: UUID(),
            clientName: "Sarah T.",
            clientInitials: "ST",
            serviceTitle: "General Labor",
            address: "4201 Fossil Creek Blvd, Fort Worth, TX",
            scheduledTime: Date().addingTimeInterval(-3600),
            status: .pending,
            clientNotes: "Large backyard cleanup. Please bring work gloves. Gate code is 1492.",
            serviceId: "service-001",
            hourlyRate: 65.0,
            materialItems: [
                MaterialLineItem(description: "Lumber", amount: 28.00),
                MaterialLineItem(description: "Screws & hardware", amount: 17.00),
            ],
            timelineEvents: [],
            prePhotos: [],
            postPhotos: [],
            billingStartTime: nil,
            elapsedBillingSeconds: 0,
            radiusExpanded: false,
            pausedReturnStatus: nil
        ),
        WorkOrder(
            id: UUID(),
            clientName: "James O.",
            clientInitials: "JO",
            serviceTitle: "Pressure Washing",
            address: "882 Summerfields Blvd, Keller, TX",
            scheduledTime: Date().addingTimeInterval(3600),
            status: .enRoute,
            clientNotes: "Driveway and back patio. Equipment provided.",
            serviceId: "service-002",
            hourlyRate: 75.0,
            materialItems: [],
            timelineEvents: [
                TimelineEvent(type: .confirmed, timestamp: Date().addingTimeInterval(-1800))
            ],
            prePhotos: [],
            postPhotos: [],
            billingStartTime: nil,
            elapsedBillingSeconds: 0,
            radiusExpanded: false,
            pausedReturnStatus: nil
        ),
        WorkOrder(
            id: UUID(),
            clientName: "Linda C.",
            clientInitials: "LC",
            serviceTitle: "Furniture Assembly",
            address: "115 RaceTrac Way, Lewisville, TX",
            scheduledTime: Date().addingTimeInterval(-7200),
            status: .clientReview,
            clientNotes: "3 IKEA bed frames and a dresser. Tools needed.",
            serviceId: "service-003",
            hourlyRate: 55.0,
            materialItems: [
                MaterialLineItem(description: "Allen wrenches", amount: 12.00),
                MaterialLineItem(description: "Extra hardware", amount: 8.00),
            ],
            timelineEvents: [
                TimelineEvent(type: .confirmed,  timestamp: Date().addingTimeInterval(-7200)),
                TimelineEvent(type: .arrived,    timestamp: Date().addingTimeInterval(-6800)),
                TimelineEvent(type: .started,    timestamp: Date().addingTimeInterval(-6600)),
                TimelineEvent(type: .completed,  timestamp: Date().addingTimeInterval(-3600))
            ],
            prePhotos: [],
            postPhotos: [],
            billingStartTime: Date().addingTimeInterval(-6600),
            elapsedBillingSeconds: 3000,
            radiusExpanded: false,
            pausedReturnStatus: nil
        )
    ]

    static let transactions: [Transaction] = [
        Transaction(
            id: UUID(),
            description: "Furniture Assembly — Linda C.",
            amount: 50.0 + 20.0,
            date: Date().addingTimeInterval(-3600),
            type: .credit
        ),
        Transaction(
            id: UUID(),
            description: "Bank Transfer",
            amount: -200.0,
            date: Date().addingTimeInterval(-86400),
            type: .payout
        ),
        Transaction(
            id: UUID(),
            description: "Pressure Washing — Prior Job",
            amount: 112.50,
            date: Date().addingTimeInterval(-172800),
            type: .credit
        )
    ]
}
