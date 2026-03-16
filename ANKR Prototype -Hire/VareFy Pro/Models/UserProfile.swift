import Foundation
import UIKit

enum DocumentCategory: String, CaseIterable, Hashable {
    case driversLicense    = "Driver's License / Gov ID"
    case businessLicense   = "Business / Trade License"
    case businessReg       = "Business Registration"
    case generalLiability  = "General Liability Insurance"
    case workersComp       = "Workers' Compensation"
    case vehicleInsurance  = "Vehicle Insurance"
    case vehicleReg        = "Vehicle Registration"
    case bondingCert       = "Bonding Certificate"
    case w9                = "W-9 / Tax Form"
    case backgroundCheck   = "Background Check Certificate"
    case oshaCard          = "OSHA Safety Card"
    case tradeCert         = "Trade Certification"

    var icon: String {
        switch self {
        case .driversLicense:   return "creditcard.fill"
        case .businessLicense:  return "building.2.fill"
        case .businessReg:      return "doc.text.fill"
        case .generalLiability: return "shield.fill"
        case .workersComp:      return "cross.fill"
        case .vehicleInsurance: return "car.fill"
        case .vehicleReg:       return "doc.plaintext.fill"
        case .bondingCert:      return "lock.shield.fill"
        case .w9:               return "dollarsign.square.fill"
        case .backgroundCheck:  return "checkmark.seal.fill"
        case .oshaCard:         return "staroflife.fill"
        case .tradeCert:        return "rosette"
        }
    }

    var groupLabel: String {
        switch self {
        case .driversLicense, .backgroundCheck:
            return "Identity & Background"
        case .businessLicense, .businessReg, .bondingCert:
            return "Business & Licensing"
        case .generalLiability, .workersComp:
            return "Insurance"
        case .vehicleInsurance, .vehicleReg:
            return "Vehicle"
        case .w9:
            return "Tax & Financial"
        case .oshaCard, .tradeCert:
            return "Certifications"
        }
    }
}

struct ProfileDocument: Hashable {
    var category: DocumentCategory
    var isUploaded: Bool = false
    var uploadedAt: Date? = nil
    /// Whether this document is toggled visible on the public profile
    var showOnProfile: Bool = false
    /// Custom label shown to clients on the public profile (uses category name if empty)
    var publicTitle: String = ""

    static func == (lhs: ProfileDocument, rhs: ProfileDocument) -> Bool {
        lhs.category == rhs.category
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(category)
    }
}

struct UserProfile {
    var id: UUID
    var firstName: String
    var lastName: String
    var businessName: String
    var rating: Double
    var isBoss: Bool
    var hourlyRate: Double
    var serviceTitle: String
    var serviceId: String

    // Personal / Account info
    var email: String
    var phone: String
    var legalAddress: String
    var city: String
    var state: String
    var zip: String
    var country: String

    // Public Profile fields
    var bio: String
    var closingMessage: String

    // Vehicle & Crew
    var vehicleYear: String
    var vehicleMake: String
    var vehicleModel: String
    var crewMembers: [String]

    // Documents
    var documents: [ProfileDocument]

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last  = lastName.first.map(String.init) ?? ""
        return first + last
    }
    var vehicleDescription: String {
        guard !vehicleYear.isEmpty else { return "No vehicle on file" }
        return "\(vehicleYear) \(vehicleMake) \(vehicleModel)"
    }
}
