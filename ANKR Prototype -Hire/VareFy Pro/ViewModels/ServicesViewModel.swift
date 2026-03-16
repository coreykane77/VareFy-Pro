import Foundation
import SwiftUI

// MARK: - ServiceGroup (display unit for ServiceCategoryView)

struct ServiceGroup: Identifiable, Hashable {
    let id: String           // groupName
    let groupName: String
    let imageName: String?
    var offerings: [ServiceOffering]

    var enabledCount: Int { offerings.filter(\.isEnabled).count }
}

// MARK: - GroupProfile (pitch + portfolio per service)

struct GroupProfile {
    var pitch: String
    var portfolioImageNames: [String]

    static let dummyPool: [String] = ["IMG_6859", "IMG_6860", "IMG_6861", "IMG_6862", "IMG_6863"]

    // Pre-populated dummy profiles for common service groups
    static let defaults: [String: GroupProfile] = [
        "Handyman": GroupProfile(
            pitch: "I've been doing general repairs for 15+ years — patching, caulking, installing, fixing whatever needs attention. I show up with my own tools and I don't leave until it's right. No job too small.",
            portfolioImageNames: ["IMG_6859", "IMG_6860"]
        ),
        "Walls & Drywall": GroupProfile(
            pitch: "12 years floating and finishing drywall. I specialize in matching existing textures — orange peel, knockdown, skip trowel. Most patches are invisible when I'm done. Water damage and remodel work welcome.",
            portfolioImageNames: ["IMG_6860", "IMG_6862"]
        ),
        "Flooring": GroupProfile(
            pitch: "I install hardwood, LVP, laminate, and tile. I do my own subfloor prep and transitions. Repair or full install — the finish is what separates a good install from one that lasts.",
            portfolioImageNames: ["IMG_6861", "IMG_6863"]
        ),
        "Painting": GroupProfile(
            pitch: "Clean lines, proper prep, no drips. I tape and protect everything before I open a can. Interior and exterior. I'll match your existing color or help you choose something new.",
            portfolioImageNames: ["IMG_6862", "IMG_6859"]
        ),
        "Lawn & Landscaping": GroupProfile(
            pitch: "Reliable weekly maintenance or one-time cleanup. I work fast and leave a clean edge. Mulch, bed work, bush trimming, sod installs. Sharp results without the landscaper markup.",
            portfolioImageNames: ["IMG_6863", "IMG_6860"]
        ),
        "Furniture Assembly": GroupProfile(
            pitch: "Thousands of flat-pack pieces assembled — IKEA, Wayfair, Amazon, all of it. I read instructions fast and I don't strip hardware. Most single-room jobs done in under two hours.",
            portfolioImageNames: ["IMG_6859", "IMG_6861"]
        ),
        "Junk Removal": GroupProfile(
            pitch: "Single item pickups to full property cleanouts. I bring my own truck and sort for donation, recycling, and dump. You see my rate — that's what you pay. No surprises.",
            portfolioImageNames: ["IMG_6860", "IMG_6863"]
        ),
        "Power Washing": GroupProfile(
            pitch: "Driveways, patios, house siding, fences. I use the right pressure for each surface — no etching concrete or stripping stain. Most jobs done same day.",
            portfolioImageNames: ["IMG_6861", "IMG_6862"]
        ),
        "Tree Services": GroupProfile(
            pitch: "Trimming, full removal, and stump grinding. I work clean and I haul everything off. Emergency storm work available. Safety first — if it's too risky, I'll tell you.",
            portfolioImageNames: ["IMG_6862", "IMG_6859"]
        ),
        "Mobile Mechanic": GroupProfile(
            pitch: "I come to you. Oil changes, brakes, batteries, diagnostics. I've worked on everything from economy cars to diesel trucks. You save the tow and I save you time.",
            portfolioImageNames: ["IMG_6863", "IMG_6861"]
        ),
    ]
}

// MARK: - ViewModel

@Observable
class ServicesViewModel {

    var offerings: [ServiceOffering] = ServiceOffering.allServices
    var groupProfiles: [String: GroupProfile] = GroupProfile.defaults

    // MARK: - Category-level queries

    /// True if any task in the category is enabled.
    func isEnabled(_ category: ServiceCategory) -> Bool {
        offerings.contains(where: { $0.category == category && $0.isEnabled })
    }

    /// Number of service groups with at least one enabled task, in this category.
    func enabledGroupCount(in category: ServiceCategory) -> Int {
        offeringGroups(in: category).filter { $0.enabledCount > 0 }.count
    }

    /// Total enabled tasks across the category.
    func enabledTaskCount(in category: ServiceCategory) -> Int {
        offerings.filter { $0.category == category && $0.isEnabled }.count
    }

    /// Number of categories with at least one enabled offering.
    var totalEnabled: Int {
        ServiceCategory.allCases.filter { isEnabled($0) }.count
    }

    /// Minimum hourly rate among all enabled tasks in this category (shown on profile).
    func hourlyRate(for category: ServiceCategory) -> Double? {
        offerings
            .filter { $0.category == category && $0.isEnabled }
            .compactMap(\.hourlyRate)
            .min()
    }

    func toolsConfirmed(for category: ServiceCategory) -> Bool {
        offerings.first(where: { $0.category == category && $0.isEnabled })?.toolsConfirmed ?? false
    }

    func toolsConfirmed(forGroup groupName: String) -> Bool {
        offerings.first(where: { $0.groupName == groupName && $0.isEnabled })?.toolsConfirmed ?? false
    }

    func setToolsConfirmed(_ confirmed: Bool, forGroup groupName: String) {
        for i in offerings.indices where offerings[i].groupName == groupName {
            offerings[i].toolsConfirmed = confirmed
        }
    }

    // MARK: - Group-level queries

    /// Offerings in a category grouped by service name, preserving definition order.
    func offeringGroups(in category: ServiceCategory) -> [ServiceGroup] {
        var groups: [ServiceGroup] = []
        var index: [String: Int] = [:]
        for offering in offerings where offering.category == category {
            if let idx = index[offering.groupName] {
                groups[idx].offerings.append(offering)
            } else {
                index[offering.groupName] = groups.count
                groups.append(ServiceGroup(
                    id: offering.groupName,
                    groupName: offering.groupName,
                    imageName: offering.imageName,
                    offerings: [offering]
                ))
            }
        }
        return groups
    }

    // MARK: - Live profile services

    /// One HireService per enabled category, carrying rate, image, pitch, and portfolio.
    var liveProfileServices: [HireService] {
        ServiceCategory.allCases.compactMap { category in
            guard isEnabled(category), let rate = hourlyRate(for: category), rate > 0 else { return nil }
            let firstEnabled = offerings.first(where: { $0.category == category && $0.isEnabled })
            let groupName    = firstEnabled?.groupName ?? ""
            let profile      = groupProfiles[groupName]
            return HireService(
                icon: category.systemImage,
                label: category.shortLabel,
                hourlyRate: rate,
                imageName: firstEnabled?.imageName,
                pitch: profile?.pitch,
                portfolioImages: profile?.portfolioImageNames ?? []
            )
        }
    }

    // MARK: - Group profile mutations

    func profile(for groupName: String) -> GroupProfile {
        groupProfiles[groupName] ?? GroupProfile(pitch: "", portfolioImageNames: [])
    }

    func updatePitch(_ pitch: String, for groupName: String) {
        groupProfiles[groupName, default: GroupProfile(pitch: "", portfolioImageNames: [])].pitch = pitch
    }

    func addSamplePhoto(to groupName: String) {
        let current = groupProfiles[groupName]?.portfolioImageNames ?? []
        guard current.count < 6 else { return }
        // Cycle through dummy pool, avoid immediate repeat
        let next = GroupProfile.dummyPool.first { !current.contains($0) }
                   ?? GroupProfile.dummyPool[current.count % GroupProfile.dummyPool.count]
        groupProfiles[groupName, default: GroupProfile(pitch: "", portfolioImageNames: [])].portfolioImageNames.append(next)
    }

    func removePhoto(at index: Int, from groupName: String) {
        guard var p = groupProfiles[groupName], p.portfolioImageNames.indices.contains(index) else { return }
        p.portfolioImageNames.remove(at: index)
        groupProfiles[groupName] = p
    }

    // MARK: - Category-level mutations

    func disable(category: ServiceCategory) {
        for i in offerings.indices where offerings[i].category == category {
            offerings[i].isEnabled      = false
            offerings[i].hourlyRate     = nil
            offerings[i].toolsConfirmed = false
        }
    }

    // MARK: - Task-level mutations

    func setEnabled(_ enabled: Bool, for id: UUID) {
        guard let idx = offerings.firstIndex(where: { $0.id == id }) else { return }
        offerings[idx].isEnabled = enabled
        if !enabled {
            offerings[idx].hourlyRate     = nil
            offerings[idx].toolsConfirmed = false
        }
    }

    func setRate(_ rate: Double, for id: UUID) {
        guard let idx = offerings.firstIndex(where: { $0.id == id }) else { return }
        offerings[idx].hourlyRate = rate
    }

    func setToolsConfirmed(_ confirmed: Bool, for id: UUID) {
        guard let idx = offerings.firstIndex(where: { $0.id == id }) else { return }
        offerings[idx].toolsConfirmed = confirmed
    }
}
