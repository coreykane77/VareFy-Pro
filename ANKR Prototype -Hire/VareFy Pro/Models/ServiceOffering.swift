import Foundation
import SwiftUI

// MARK: - Category (broad grouping)

enum ServiceCategory: String, CaseIterable, Hashable, Identifiable {
    var id: String { rawValue }
    case homeProperty   = "Home & Property"
    case cleaning       = "Cleaning & Maintenance"
    case automotive     = "Automotive & Equipment"
    case events         = "Events & Hospitality"
    case personal       = "Personal & Lifestyle"
    case photography    = "Photography & Video"
    case realEstate     = "Real Estate"
    case tech           = "Tech & Creative"

    /// Representative image shown in the category list (MyServicesView)
    var representativeImageName: String {
        switch self {
        case .homeProperty:  return "Handyman"
        case .cleaning:      return "Cleaning & Maintenance"
        case .automotive:    return "Mobile Mechanic"
        case .events:        return "events"
        case .personal:      return "Moving & Packing"
        case .photography:   return "Photography"
        case .realEstate:    return "Home Stage"
        case .tech:          return "Smart Home"
        }
    }

    var systemImage: String {
        switch self {
        case .homeProperty:  return "house.fill"
        case .cleaning:      return "sparkles"
        case .automotive:    return "car.fill"
        case .events:        return "party.popper.fill"
        case .personal:      return "person.fill"
        case .photography:   return "camera.fill"
        case .realEstate:    return "building.2.fill"
        case .tech:          return "laptopcomputer"
        }
    }

    var shortLabel: String {
        switch self {
        case .homeProperty:  return "Home"
        case .cleaning:      return "Cleaning"
        case .automotive:    return "Auto"
        case .events:        return "Events"
        case .personal:      return "Personal"
        case .photography:   return "Photo"
        case .realEstate:    return "Real Estate"
        case .tech:          return "Tech"
        }
    }
}

// MARK: - Model
// Each ServiceOffering is a specific task (e.g. "Tape, Texture & Float")
// grouped under a service name (e.g. "Walls & Drywall").

struct ServiceOffering: Identifiable, Hashable {
    let id: UUID
    let name: String           // specific task: "Tape, Texture & Float"
    let groupName: String      // service name:  "Walls & Drywall"
    let category: ServiceCategory
    let imageName: String?     // asset name shared across the group
    var isEnabled: Bool
    var hourlyRate: Double?
    var toolsConfirmed: Bool

    init(name: String, group: String, category: ServiceCategory, imageName: String? = nil) {
        self.id             = UUID()
        self.name           = name
        self.groupName      = group
        self.category       = category
        self.imageName      = imageName
        self.isEnabled      = false
        self.hourlyRate     = nil
        self.toolsConfirmed = false
    }
}

// MARK: - Seed Data

extension ServiceOffering {
    static let allServices: [ServiceOffering] = [

        // ─── HOME & PROPERTY ──────────────────────────────────────────────

        // Handyman
        .init(name: "General Repairs & Odd Jobs",     group: "Handyman",          category: .homeProperty, imageName: "Handyman"),
        .init(name: "Furniture Assembly",              group: "Handyman",          category: .homeProperty, imageName: "Handyman"),
        .init(name: "Hanging, Shelving & Mirrors",     group: "Handyman",          category: .homeProperty, imageName: "Handyman"),
        .init(name: "Baby-Proofing & Safety Install",  group: "Handyman",          category: .homeProperty, imageName: "Handyman"),
        .init(name: "Caulk, Seal & Weatherstrip",      group: "Handyman",          category: .homeProperty, imageName: "Handyman"),

        // Walls & Drywall
        .init(name: "Drywall Repair & Patching",       group: "Walls & Drywall",   category: .homeProperty, imageName: "Walls & Drywall"),
        .init(name: "New Drywall Install & Finishing", group: "Walls & Drywall",   category: .homeProperty, imageName: "Walls & Drywall"),
        .init(name: "Accent Walls",                    group: "Walls & Drywall",   category: .homeProperty, imageName: "Walls & Drywall"),

        // Flooring
        .init(name: "Floor Repair / Section Replace",  group: "Flooring",          category: .homeProperty, imageName: "Flooring"),
        .init(name: "Hardwood Installation",           group: "Flooring",          category: .homeProperty, imageName: "Flooring"),
        .init(name: "Laminate / LVP Installation",     group: "Flooring",          category: .homeProperty, imageName: "Flooring"),
        .init(name: "Tile Floor Installation",         group: "Flooring",          category: .homeProperty, imageName: "Flooring"),
        .init(name: "Carpet Installation",             group: "Flooring",          category: .homeProperty, imageName: "Flooring"),
        .init(name: "Sand & Refinish (Hardwood)",      group: "Flooring",          category: .homeProperty, imageName: "Flooring"),

        // Interior Carpentry
        .init(name: "Trim, Baseboard & Crown Molding", group: "Interior Carpentry",category: .homeProperty, imageName: "Interior Carpentry"),
        .init(name: "Built-Ins & Shelving",            group: "Interior Carpentry",category: .homeProperty, imageName: "Interior Carpentry"),
        .init(name: "Stair Repair & Railing",          group: "Interior Carpentry",category: .homeProperty, imageName: "Interior Carpentry"),
        .init(name: "Custom Millwork & Finish Carpentry", group: "Interior Carpentry",category: .homeProperty, imageName: "Interior Carpentry"),

        // Painting
        .init(name: "Interior Painting",               group: "Painting",          category: .homeProperty, imageName: "Painting"),
        .init(name: "Exterior Painting",               group: "Painting",          category: .homeProperty, imageName: "Painting"),
        .init(name: "Staining & Sealing",              group: "Painting",          category: .homeProperty, imageName: "Painting"),
        .init(name: "Touch-Up & Spot Repair",          group: "Painting",          category: .homeProperty, imageName: "Painting"),

        // Doors
        .init(name: "Door Installation",               group: "Doors",             category: .homeProperty, imageName: "Doors"),
        .init(name: "Sliding & French Doors",          group: "Doors",             category: .homeProperty, imageName: "Doors"),
        .init(name: "Door Repair & Adjustment",        group: "Doors",             category: .homeProperty, imageName: "Doors"),
        .init(name: "Screen / Storm Door",             group: "Doors",             category: .homeProperty, imageName: "Doors"),

        // Windows
        .init(name: "Window Installation",             group: "Windows",           category: .homeProperty, imageName: "Windows"),
        .init(name: "Window Repair / Reseal",          group: "Windows",           category: .homeProperty, imageName: "Windows"),
        .init(name: "Screen Repair / Replace",         group: "Windows",           category: .homeProperty, imageName: "Windows"),

        // Mounting
        .init(name: "TV Mounting",                     group: "Mounting",          category: .homeProperty, imageName: "Mounting"),
        .init(name: "General Mounting",                group: "Mounting",          category: .homeProperty, imageName: "Mounting"),

        // Electrical
        .init(name: "Outlet & Switch",                  group: "Electrical",        category: .homeProperty, imageName: "Electrical"),
        .init(name: "Fixture & Fan",                   group: "Electrical",        category: .homeProperty, imageName: "Electrical"),
        .init(name: "EV Charger",                      group: "Electrical",        category: .homeProperty, imageName: "Electrical"),
        .init(name: "Panel & Breaker",                 group: "Electrical",        category: .homeProperty, imageName: "Electrical"),
        .init(name: "Troubleshoot & Repair",           group: "Electrical",        category: .homeProperty, imageName: "Electrical"),

        // Plumbing
        .init(name: "Fixture & Disposal Install",      group: "Plumbing",          category: .homeProperty, imageName: "Plumbing"),
        .init(name: "Leak & Pipe Repair",              group: "Plumbing",          category: .homeProperty, imageName: "Plumbing"),
        .init(name: "Drain & Clog",                    group: "Plumbing",          category: .homeProperty, imageName: "Plumbing"),
        .init(name: "Water Heater Install / Repair",   group: "Plumbing",          category: .homeProperty, imageName: "Plumbing"),

        // HVAC
        .init(name: "AC & Heating Service",            group: "HVAC",              category: .homeProperty, imageName: "HVAC"),
        .init(name: "Refrigerant Recharge & Leak Check", group: "HVAC",            category: .homeProperty, imageName: "HVAC"),
        .init(name: "Duct & Vent Work",                group: "HVAC",              category: .homeProperty, imageName: "HVAC"),
        .init(name: "Mini Split Install",              group: "HVAC",              category: .homeProperty, imageName: "HVAC"),
        .init(name: "Thermostat Install",              group: "HVAC",              category: .homeProperty, imageName: "HVAC"),
        .init(name: "Filter Change & Tune-Up",         group: "HVAC",              category: .homeProperty, imageName: "HVAC"),

        // Appliance Repair
        .init(name: "Appliance Repair",                group: "Appliances",  category: .homeProperty, imageName: "Appliance"),
        .init(name: "Appliance Installation",          group: "Appliances",  category: .homeProperty, imageName: "Appliance"),

        // Roofing
        .init(name: "Roof Repair / Patch",             group: "Roofing",           category: .homeProperty, imageName: "Roofing"),
        .init(name: "Full Roof Replacement",           group: "Roofing",           category: .homeProperty, imageName: "Roofing"),
        .init(name: "Roof Inspection",                 group: "Roofing",           category: .homeProperty, imageName: "Roofing"),
        .init(name: "Gutter Install / Repair",         group: "Roofing",           category: .homeProperty, imageName: "Roofing"),
        .init(name: "Skylight Install / Repair",       group: "Roofing",           category: .homeProperty, imageName: "Roofing"),

        // Garage Door
        .init(name: "Repair & Opener Service",         group: "Garage",       category: .homeProperty, imageName: "Garage Door"),
        .init(name: "New Door Installation",           group: "Garage",       category: .homeProperty, imageName: "Garage Door"),

        // Insulation
        .init(name: "Attic Insulation (Batt & Blown-In)", group: "Insulation & Spray Foam",     category: .homeProperty, imageName: "Insulation"),
        .init(name: "Wall & Crawlspace Insulation",    group: "Insulation & Spray Foam",        category: .homeProperty, imageName: "Insulation"),
        .init(name: "Spray Foam",                      group: "Insulation & Spray Foam",        category: .homeProperty, imageName: "Insulation"),
        .init(name: "Air Sealing",                     group: "Insulation & Spray Foam",        category: .homeProperty, imageName: "Insulation"),

        // Masonry & Stucco
        .init(name: "Brick, Stone & Veneer",           group: "Masonry & Stucco",  category: .homeProperty, imageName: "Masonry"),
        .init(name: "Stucco Application / Repair",     group: "Masonry & Stucco",  category: .homeProperty, imageName: "Masonry"),
        .init(name: "Retaining Walls",                 group: "Masonry & Stucco",  category: .homeProperty, imageName: "Masonry"),
        .init(name: "Stone & Brick Patio",             group: "Masonry & Stucco",  category: .homeProperty, imageName: "Masonry"),
        .init(name: "Fire Pit & Outdoor Kitchen",      group: "Masonry & Stucco",  category: .homeProperty, imageName: "Masonry"),

        // Concrete & Flatwork
        .init(name: "Concrete Repair / Crack Fill",    group: "Concrete & Flatwork",category: .homeProperty, imageName: "Concrete"),
        .init(name: "New Pour (Driveway, Slab, Walkway)",group: "Concrete & Flatwork",category: .homeProperty, imageName: "Concrete"),
        .init(name: "Stamped Concrete",                group: "Concrete & Flatwork",category: .homeProperty, imageName: "Concrete"),
        .init(name: "Concrete Leveling / Grinding",    group: "Concrete & Flatwork",category: .homeProperty, imageName: "Concrete"),

        // Tile & Backsplash
        .init(name: "Wall & Backsplash",               group: "Tile & Backsplash", category: .homeProperty, imageName: "Tile"),
        .init(name: "Tub & Shower",                    group: "Tile & Backsplash", category: .homeProperty, imageName: "Tile"),
        .init(name: "Floor & Patio",                   group: "Tile & Backsplash", category: .homeProperty, imageName: "Tile"),
        .init(name: "Grout",                           group: "Tile & Backsplash", category: .homeProperty, imageName: "Tile"),

        // Countertops
        .init(name: "Template & Measure",              group: "Countertops",       category: .homeProperty, imageName: "Countertops"),
        .init(name: "Countertop Installation",         group: "Countertops",       category: .homeProperty, imageName: "Countertops"),
        .init(name: "Repair & Restoration",            group: "Countertops",       category: .homeProperty, imageName: "Countertops"),
        .init(name: "Removal & Demo",                  group: "Countertops",       category: .homeProperty, imageName: "Countertops"),

        // Cabinets
        .init(name: "Cabinet Installation",            group: "Cabinets",          category: .homeProperty, imageName: "Cabinets"),
        .init(name: "Cabinet Refacing",                group: "Cabinets",          category: .homeProperty, imageName: "Cabinets"),
        .init(name: "Cabinet Painting / Refinishing",  group: "Cabinets",          category: .homeProperty, imageName: "Cabinets"),
        .init(name: "Cabinet Repair",                  group: "Cabinets",          category: .homeProperty, imageName: "Cabinets"),
        .init(name: "Hardware & Soft-Close Upgrade",   group: "Cabinets",          category: .homeProperty, imageName: "Cabinets"),

        // Exterior Carpentry
        .init(name: "Deck Build",                      group: "Exterior Carpentry",category: .homeProperty, imageName: "Exterior Carpentry"),
        .init(name: "Deck Repair & Board Replace",     group: "Exterior Carpentry",category: .homeProperty, imageName: "Exterior Carpentry"),
        .init(name: "Deck Stain, Seal & Refinish",     group: "Exterior Carpentry",category: .homeProperty, imageName: "Exterior Carpentry"),
        .init(name: "Pergola / Patio Cover",           group: "Exterior Carpentry",category: .homeProperty, imageName: "Exterior Carpentry"),
        .init(name: "Steps & Railing",                 group: "Exterior Carpentry",category: .homeProperty, imageName: "Exterior Carpentry"),

        // Fence & Gate
        .init(name: "Fence — Install or Repair",       group: "Fence & Gate",      category: .homeProperty, imageName: "Fence"),
        .init(name: "Gate — Install or Repair",        group: "Fence & Gate",      category: .homeProperty, imageName: "Fence"),

        // Lawn & Landscaping
        .init(name: "Lawn Maintenance (Mow, Edge, Trim)", group: "Lawn & Landscaping", category: .homeProperty, imageName: "Lawn & Landscaping"),
        .init(name: "Full Landscaping Install",        group: "Lawn & Landscaping",category: .homeProperty, imageName: "Lawn & Landscaping"),
        .init(name: "Mulch & Bed Work",                group: "Lawn & Landscaping",category: .homeProperty, imageName: "Lawn & Landscaping"),
        .init(name: "Sod / Artificial Turf Install",   group: "Lawn & Landscaping",category: .homeProperty, imageName: "Lawn & Landscaping"),
        .init(name: "Drainage Solutions",              group: "Lawn & Landscaping",category: .homeProperty, imageName: "Lawn & Landscaping"),
        .init(name: "Holiday Light Install & Takedown",group: "Lawn & Landscaping",category: .homeProperty, imageName: "Lawn & Landscaping"),

        // Irrigation
        .init(name: "New System Install",              group: "Irrigation",        category: .homeProperty, imageName: "Irrigation"),
        .init(name: "Repair & Zone Fix",               group: "Irrigation",        category: .homeProperty, imageName: "Irrigation"),
        .init(name: "Seasonal Blowout / Winterize",    group: "Irrigation",        category: .homeProperty, imageName: "Irrigation"),

        // Snow & Ice
        .init(name: "Snow Plowing",                    group: "Snow & Ice",        category: .homeProperty, imageName: "Snow"),
        .init(name: "Shoveling & Salting",             group: "Snow & Ice",        category: .homeProperty, imageName: "Snow"),
        .init(name: "Ice Dam Removal",                 group: "Snow & Ice",        category: .homeProperty, imageName: "Snow"),

        // Pool & Spa
        .init(name: "Weekly Cleaning & Chemicals",     group: "Pool & Spa",        category: .homeProperty, imageName: "Pool & Spa"),
        .init(name: "Equipment Repair",                group: "Pool & Spa",        category: .homeProperty, imageName: "Pool & Spa"),
        .init(name: "Opening / Closing Service",       group: "Pool & Spa",        category: .homeProperty, imageName: "Pool & Spa"),

        // Water & Utilities
        .init(name: "Septic Service",                  group: "Water & Utilities", category: .homeProperty, imageName: "Septic"),
        .init(name: "Well Pump Repair",                group: "Water & Utilities", category: .homeProperty, imageName: "Septic"),
        .init(name: "Water Softener Install",          group: "Water & Utilities", category: .homeProperty, imageName: "Septic"),
        .init(name: "Sump Pump Install / Repair",      group: "Water & Utilities", category: .homeProperty, imageName: "Septic"),

        // Locksmith & Access
        .init(name: "Rekey / Lock Install",            group: "Locksmith & Access",category: .homeProperty, imageName: "Locksmith"),
        .init(name: "Lockout Service",                 group: "Locksmith & Access",category: .homeProperty, imageName: "Locksmith"),
        .init(name: "Smart Lock Install",              group: "Locksmith & Access",category: .homeProperty, imageName: "Locksmith"),

        // Power Washing
        .init(name: "Driveway & Concrete Wash",        group: "Power Washing",     category: .homeProperty, imageName: "Pressure Washing"),
        .init(name: "House & Siding Wash",             group: "Power Washing",     category: .homeProperty, imageName: "Pressure Washing"),
        .init(name: "Deck & Patio Wash",               group: "Power Washing",     category: .homeProperty, imageName: "Pressure Washing"),
        .init(name: "Roof Soft Wash",                  group: "Power Washing",     category: .homeProperty, imageName: "Pressure Washing"),

        // Remodeling & Renovation
        .init(name: "Kitchen Remodel",                 group: "Remodeling & Renovation",        category: .homeProperty, imageName: "remodel"),
        .init(name: "Bathroom Remodel",                group: "Remodeling & Renovation",        category: .homeProperty, imageName: "remodel"),
        .init(name: "Basement Finish",                 group: "Remodeling & Renovation",        category: .homeProperty, imageName: "remodel"),
        .init(name: "Room Addition / ADU",             group: "Remodeling & Renovation",        category: .homeProperty, imageName: "remodel"),

        // Interior Design
        .init(name: "Space Planning & Layout",         group: "Interior Design",   category: .homeProperty, imageName: "Interior Design"),
        .init(name: "Furniture & Decor Styling",       group: "Interior Design",   category: .homeProperty, imageName: "Interior Design"),
        .init(name: "Color & Material Selection",      group: "Interior Design",   category: .homeProperty, imageName: "Interior Design"),

        // Pest Control
        .init(name: "General Treatment",               group: "Pest Control",      category: .homeProperty, imageName: "Pest Control"),
        .init(name: "Bed Bug Treatment",               group: "Pest Control",      category: .homeProperty, imageName: "Pest Control"),
        .init(name: "Termite Treatment",               group: "Pest Control",      category: .homeProperty, imageName: "Pest Control"),
        .init(name: "Rodent Control",                  group: "Pest Control",      category: .homeProperty, imageName: "Pest Control"),
        .init(name: "Mosquito / Tick Spray",           group: "Pest Control",      category: .homeProperty, imageName: "Pest Control"),

        // Water & Mold Remediation
        .init(name: "Water Damage & Dry-Out",          group: "Water & Mold Remediation", category: .homeProperty, imageName: "Water Remediation"),
        .init(name: "Mold Testing & Remediation",      group: "Water & Mold Remediation", category: .homeProperty, imageName: "Water Remediation"),
        .init(name: "Fire & Smoke Damage Cleanup",     group: "Water & Mold Remediation", category: .homeProperty, imageName: "Water Remediation"),

        // Solar
        .init(name: "Solar Panel Install",             group: "Solar",             category: .homeProperty, imageName: "Solar"),
        .init(name: "Repair & Maintenance",            group: "Solar",             category: .homeProperty, imageName: "Solar"),
        .init(name: "Battery Backup System",           group: "Solar",             category: .homeProperty, imageName: "Solar"),

        // Siding
        .init(name: "Siding Install / Replace",        group: "Siding",            category: .homeProperty, imageName: "Siding"),
        .init(name: "Siding Repair",                   group: "Siding",            category: .homeProperty, imageName: "Siding"),
        .init(name: "Soffit & Fascia",                 group: "Siding",            category: .homeProperty, imageName: "Siding"),

        // Foundation Repair
        .init(name: "Crack Injection / Seal",          group: "Foundation Repair", category: .homeProperty, imageName: "Foundation"),
        .init(name: "Pier & Underpinning",             group: "Foundation Repair", category: .homeProperty, imageName: "Foundation"),
        .init(name: "Crawlspace Waterproofing",        group: "Foundation Repair", category: .homeProperty, imageName: "Foundation"),

        // Chimney & Fireplace
        .init(name: "Chimney Sweep & Clean",           group: "Chimney & Fireplace",category: .homeProperty, imageName: "Chimeny"),
        .init(name: "Fireplace Insert Install",        group: "Chimney & Fireplace",category: .homeProperty, imageName: "Chimeny"),
        .init(name: "Chimney Repair / Cap",            group: "Chimney & Fireplace",category: .homeProperty, imageName: "Chimeny"),

        // Machine Operator
        .init(name: "Land Clearing",                   group: "Machine Operator",  category: .homeProperty, imageName: "Machine Work"),
        .init(name: "Grading & Excavation",            group: "Machine Operator",  category: .homeProperty, imageName: "Machine Work"),
        .init(name: "Trenching",                       group: "Machine Operator",  category: .homeProperty, imageName: "Machine Work"),
        .init(name: "Material Moving & Site Prep",     group: "Machine Operator",  category: .homeProperty, imageName: "Machine Work"),

        // Tree Services
        .init(name: "Tree Trimming / Pruning",         group: "Tree Services",     category: .homeProperty, imageName: "Tree"),
        .init(name: "Tree Removal",                    group: "Tree Services",     category: .homeProperty, imageName: "Tree"),
        .init(name: "Stump Grinding",                  group: "Tree Services",     category: .homeProperty, imageName: "Tree"),
        .init(name: "Emergency Tree Work",             group: "Tree Services",     category: .homeProperty, imageName: "Tree"),

        // Accessibility Modifications
        .init(name: "Grab Bars & Handrails",           group: "Accessibility Modifications", category: .homeProperty, imageName: "accessibility Modifications"),
        .init(name: "Wheelchair Ramp",                 group: "Accessibility Modifications", category: .homeProperty, imageName: "accessibility Modifications"),
        .init(name: "Walk-In Tub / Roll-In Shower",    group: "Accessibility Modifications", category: .homeProperty, imageName: "accessibility Modifications"),
        .init(name: "Stair Lift Install",              group: "Accessibility Modifications", category: .homeProperty, imageName: "accessibility Modifications"),

        // ─── CLEANING & MAINTENANCE ──────────────────────────────────────

        .init(name: "House Cleaning / Maid Service",   group: "Cleaning",          category: .cleaning, imageName: "Cleaning & Maintenance"),
        .init(name: "Deep Clean",                      group: "Cleaning",          category: .cleaning, imageName: "Cleaning & Maintenance"),
        .init(name: "Move-In / Move-Out Clean",        group: "Cleaning",          category: .cleaning, imageName: "Cleaning & Maintenance"),
        .init(name: "Post-Construction Clean",         group: "Cleaning",          category: .cleaning, imageName: "Cleaning & Maintenance"),
        .init(name: "Window Cleaning",                 group: "Cleaning",          category: .cleaning, imageName: "Cleaning & Maintenance"),

        .init(name: "Haul-Away (Single Load)",         group: "Junk Removal",      category: .cleaning, imageName: "Junk removal"),
        .init(name: "Full Property Cleanout",          group: "Junk Removal",      category: .cleaning, imageName: "Junk removal"),
        .init(name: "Furniture / Appliance Removal",   group: "Junk Removal",      category: .cleaning, imageName: "Junk removal"),

        .init(name: "Full Duct Cleaning",              group: "Air Duct Cleaning", category: .cleaning, imageName: "Air Duct"),
        .init(name: "Dryer Vent Cleaning",             group: "Air Duct Cleaning", category: .cleaning, imageName: "Air Duct"),
        .init(name: "Duct Sanitization",               group: "Air Duct Cleaning", category: .cleaning, imageName: "Air Duct"),

        // ─── AUTOMOTIVE & EQUIPMENT ──────────────────────────────────────

        .init(name: "Interior Detail",                 group: "Mobile Detailing",  category: .automotive, imageName: "Mobile Detailing"),
        .init(name: "Exterior Wash & Wax",             group: "Mobile Detailing",  category: .automotive, imageName: "Mobile Detailing"),
        .init(name: "Full Detail Package",             group: "Mobile Detailing",  category: .automotive, imageName: "Mobile Detailing"),
        .init(name: "Ceramic Coat",                    group: "Mobile Detailing",  category: .automotive, imageName: "Mobile Detailing"),

        .init(name: "Oil Change & Fluid Service",      group: "Mobile Mechanic",   category: .automotive, imageName: "Mobile Mechanic"),
        .init(name: "Brake Repair",                    group: "Mobile Mechanic",   category: .automotive, imageName: "Mobile Mechanic"),
        .init(name: "Tire Service",                    group: "Mobile Mechanic",   category: .automotive, imageName: "Mobile Mechanic"),
        .init(name: "Battery & Electrical",            group: "Mobile Mechanic",   category: .automotive, imageName: "Mobile Mechanic"),

        .init(name: "Jump Start",                      group: "Roadside Assistance",category: .automotive, imageName: "roadside"),
        .init(name: "Flat Tire Change",                group: "Roadside Assistance",category: .automotive, imageName: "roadside"),
        .init(name: "Lockout Service",                 group: "Roadside Assistance",category: .automotive, imageName: "roadside"),
        .init(name: "Fuel Delivery",                   group: "Roadside Assistance",category: .automotive, imageName: "roadside"),

        // ─── EVENTS & HOSPITALITY ────────────────────────────────────────

        .init(name: "Event Setup & Teardown",          group: "Events & Hospitality",category: .events, imageName: "events"),
        .init(name: "Event Staffing & Waitstaff",      group: "Events & Hospitality",category: .events, imageName: "events"),
        .init(name: "Venue Decoration",                group: "Events & Hospitality",category: .events, imageName: "events"),
        .init(name: "Day-Of Coordination",             group: "Events & Hospitality",category: .events, imageName: "events"),

        .init(name: "Private Dinner Event",            group: "Private Chef & Catering",category: .events, imageName: "Personal Chef"),
        .init(name: "Meal Prep Service",               group: "Private Chef & Catering",category: .events, imageName: "Personal Chef"),
        .init(name: "Full Catering",                   group: "Private Chef & Catering",category: .events, imageName: "Personal Chef"),

        .init(name: "Event Bartending",                group: "Bartending",        category: .events, imageName: "Bartender"),
        .init(name: "Mobile Bar Setup",                group: "Bartending",        category: .events, imageName: "Bartender"),

        .init(name: "Tent & Table Setup",              group: "Party Rentals & Setup",category: .events, imageName: "party rentals"),
        .init(name: "Bounce House / Inflatable",       group: "Party Rentals & Setup",category: .events, imageName: "party rentals"),
        .init(name: "Décor & Lighting",                group: "Party Rentals & Setup",category: .events, imageName: "party rentals"),

        // ─── PERSONAL & LIFESTYLE ────────────────────────────────────────

        .init(name: "Errands & Grocery Shopping",      group: "Personal Assistance",category: .personal, imageName: "personal ast"),
        .init(name: "Scheduling & Admin",              group: "Personal Assistance",category: .personal, imageName: "personal ast"),
        .init(name: "Home Watch & Check-Ins",          group: "Personal Assistance",category: .personal, imageName: "personal ast"),

        .init(name: "Full Move (Load & Unload)",       group: "Moving & Packing",  category: .personal, imageName: "Moving & Packing"),
        .init(name: "Packing Only",                    group: "Moving & Packing",  category: .personal, imageName: "Moving & Packing"),
        .init(name: "Furniture Moving (Same Home)",    group: "Moving & Packing",  category: .personal, imageName: "Moving & Packing"),

        .init(name: "Swedish Massage",                 group: "Massage Therapy",   category: .personal, imageName: "Massage Therapy"),
        .init(name: "Deep Tissue",                     group: "Massage Therapy",   category: .personal, imageName: "Massage Therapy"),
        .init(name: "Sports Massage",                  group: "Massage Therapy",   category: .personal, imageName: "Massage Therapy"),
        .init(name: "Prenatal Massage",                group: "Massage Therapy",   category: .personal, imageName: "Massage Therapy"),

        .init(name: "Personal Training",               group: "Fitness & Wellness",category: .personal, imageName: "fitness"),
        .init(name: "Yoga / Pilates Session",          group: "Fitness & Wellness",category: .personal, imageName: "fitness"),
        .init(name: "Nutrition Coaching",              group: "Fitness & Wellness",category: .personal, imageName: "fitness"),
        .init(name: "Meditation & Mindfulness",        group: "Fitness & Wellness",category: .personal, imageName: "fitness"),

        .init(name: "Companion Care",                  group: "Senior Care",       category: .personal, imageName: "senior care"),
        .init(name: "Light Housekeeping",              group: "Senior Care",       category: .personal, imageName: "senior care"),
        .init(name: "Transportation & Errands",        group: "Senior Care",       category: .personal, imageName: "senior care"),

        .init(name: "Dog Walking",                     group: "Pet Services",      category: .personal, imageName: "Pet Services"),
        .init(name: "Pet Sitting",                     group: "Pet Services",      category: .personal, imageName: "Pet Services"),
        .init(name: "Mobile Grooming",                 group: "Pet Services",      category: .personal, imageName: "Pet Services"),
        .init(name: "Pet Training",                    group: "Pet Services",      category: .personal, imageName: "Pet Services"),

        .init(name: "Haircut & Style",                 group: "Mobile Beauty",     category: .personal, imageName: "beauty"),
        .init(name: "Color & Highlights",              group: "Mobile Beauty",     category: .personal, imageName: "beauty"),
        .init(name: "Nails (Mani / Pedi)",             group: "Mobile Beauty",     category: .personal, imageName: "beauty"),
        .init(name: "Lash Extensions",                 group: "Mobile Beauty",     category: .personal, imageName: "beauty"),
        .init(name: "Waxing & Hair Removal",           group: "Mobile Beauty",     category: .personal, imageName: "beauty"),
        .init(name: "Makeup Application",              group: "Mobile Beauty",     category: .personal, imageName: "beauty"),

        .init(name: "Academic Tutoring",               group: "Tutoring & Lessons",category: .personal, imageName: "Tutor"),
        .init(name: "Test Prep (SAT / ACT)",           group: "Tutoring & Lessons",category: .personal, imageName: "Tutor"),
        .init(name: "Music Lessons",                   group: "Tutoring & Lessons",category: .personal, imageName: "Tutor"),
        .init(name: "Language Lessons",                group: "Tutoring & Lessons",category: .personal, imageName: "Tutor"),

        // ─── PHOTOGRAPHY & VIDEO ─────────────────────────────────────────

        // Real Estate & Virtual Tours
        .init(name: "Listing Photography",             group: "Real Estate & Virtual Tours", category: .photography, imageName: "Photography"),
        .init(name: "Virtual Tour / Matterport",       group: "Real Estate & Virtual Tours", category: .photography, imageName: "Photography"),
        .init(name: "Aerial Add-On",                   group: "Real Estate & Virtual Tours", category: .photography, imageName: "Photography"),

        // Events & Weddings
        .init(name: "Wedding Coverage",                group: "Events & Weddings",  category: .photography, imageName: "Photography"),
        .init(name: "Event Photography",               group: "Events & Weddings",  category: .photography, imageName: "Photography"),
        .init(name: "Engagement Session",              group: "Events & Weddings",  category: .photography, imageName: "Photography"),

        // Portrait & Family
        .init(name: "Family Session",                  group: "Portrait & Family",  category: .photography, imageName: "Photography"),
        .init(name: "Individual Portrait",             group: "Portrait & Family",  category: .photography, imageName: "Photography"),
        .init(name: "Headshots",                       group: "Portrait & Family",  category: .photography, imageName: "Photography"),
        .init(name: "Newborn & Maternity",             group: "Portrait & Family",  category: .photography, imageName: "Photography"),

        // Drone & Aerial
        .init(name: "Aerial Photography",              group: "Drone & Aerial",     category: .photography, imageName: "Photography"),
        .init(name: "Aerial Video",                    group: "Drone & Aerial",     category: .photography, imageName: "Photography"),
        .init(name: "Mapping & Survey",                group: "Drone & Aerial",     category: .photography, imageName: "Photography"),

        // Commercial & Product
        .init(name: "Product Photography",             group: "Commercial & Product", category: .photography, imageName: "Photography"),
        .init(name: "Brand & Lifestyle",               group: "Commercial & Product", category: .photography, imageName: "Photography"),
        .init(name: "Food & Beverage",                 group: "Commercial & Product", category: .photography, imageName: "Photography"),
        .init(name: "Architecture & Interior",         group: "Commercial & Product", category: .photography, imageName: "Photography"),

        // Videography
        .init(name: "Event / Wedding Video",           group: "Videography",        category: .photography, imageName: "videographer"),
        .init(name: "Promo & Brand Video",             group: "Videography",        category: .photography, imageName: "videographer"),
        .init(name: "Social Media Content",            group: "Videography",        category: .photography, imageName: "videographer"),

        // ─── REAL ESTATE ─────────────────────────────────────────────────

        .init(name: "Full Staging Package",            group: "Home Staging",      category: .realEstate, imageName: "Home Stage"),
        .init(name: "Consultation Only",               group: "Home Staging",      category: .realEstate, imageName: "Home Stage"),

        .init(name: "Full Home Inspection",            group: "Home Inspection",   category: .realEstate, imageName: "home inspector"),
        .init(name: "Pre-Listing Inspection",          group: "Home Inspection",   category: .realEstate, imageName: "home inspector"),
        .init(name: "Specific Systems Inspection",     group: "Home Inspection",   category: .realEstate, imageName: "home inspector"),

        // ─── TECH & CREATIVE ─────────────────────────────────────────────

        .init(name: "Device Setup & Config",           group: "Smart Home Setup",  category: .tech, imageName: "Smart Home"),
        .init(name: "Network / Wi-Fi Setup",           group: "Smart Home Setup",  category: .tech, imageName: "Smart Home"),
        .init(name: "Security Camera Install",         group: "Smart Home Setup",  category: .tech, imageName: "Smart Home"),

        .init(name: "Laptop / Desktop Repair",         group: "Computer & Device Repair",category: .tech, imageName: "device repair"),
        .init(name: "Phone / Tablet Repair",           group: "Computer & Device Repair",category: .tech, imageName: "device repair"),
        .init(name: "Data Recovery",                   group: "Computer & Device Repair",category: .tech, imageName: "device repair"),

        .init(name: "TV Mount & Setup",                group: "TV & Audio Setup",  category: .tech, imageName: "TV Audio"),
        .init(name: "Sound Bar / Surround Sound",      group: "TV & Audio Setup",  category: .tech, imageName: "TV Audio"),
        .init(name: "Home Theater Build",              group: "TV & Audio Setup",  category: .tech, imageName: "TV Audio"),

        .init(name: "On-Site Tech Help",               group: "IT Support",        category: .tech, imageName: "it support"),
        .init(name: "Remote Support",                  group: "IT Support",        category: .tech, imageName: "it support"),
        .init(name: "Small Business IT",               group: "IT Support",        category: .tech, imageName: "it support"),

        .init(name: "Interior Mural",                  group: "Murals & Decorative Art",      category: .tech, imageName: "mural"),
        .init(name: "Exterior Mural",                  group: "Murals & Decorative Art",      category: .tech, imageName: "mural"),
        .init(name: "Custom Canvas / Faux Finish",     group: "Murals & Decorative Art",      category: .tech, imageName: "mural"),
    ]
}

// MARK: - Search Aliases

extension ServiceOffering {
    static let searchAliases: [String: [String]] = [
        // Plumbing
        "toilet": ["Fixture Replacement"], "sink": ["Fixture Replacement"],
        "faucet": ["Fixture Replacement"], "drain": ["Drain Cleaning"],
        "leak": ["Leak Repair"], "water heater": ["Water Heater"],
        "clog": ["Drain Cleaning"], "garbage disposal": ["Garbage Disposal"],
        "septic": ["Septic Service"], "well pump": ["Well Pump"],
        // Electrical
        "outlet": ["Outlets"], "breaker": ["Panel"], "wiring": ["Outlets"],
        "ceiling fan": ["Ceiling Fan"], "ev charger": ["EV Charger"],
        "panel": ["Panel"], "light fixture": ["Lighting"],
        // HVAC
        "ac": ["AC / Furnace"], "furnace": ["AC / Furnace"],
        "thermostat": ["Thermostat"], "mini split": ["Mini Split"],
        "duct": ["Duct & Vent"], "filter": ["Filter Change"],
        // Flooring
        "hardwood": ["Hardwood"], "laminate": ["Laminate"],
        "vinyl": ["Laminate / LVP"], "carpet": ["Carpet"],
        "floor repair": ["Floor Repair"], "refinish": ["Sand & Refinish"],
        // Walls
        "drywall": ["Drywall Repair", "New Drywall", "Tape, Texture"],
        "patch": ["Drywall Repair"], "texture": ["Tape, Texture"],
        "shiplap": ["Shiplap"], "paneling": ["Shiplap"],
        // Painting
        "paint": ["Interior Painting", "Exterior Painting"],
        "stain": ["Staining & Sealing"], "touch up": ["Touch-Up"],
        // Lawn
        "mow": ["Lawn Maintenance"], "mowing": ["Lawn Maintenance"],
        "grass": ["Lawn Maintenance"], "sod": ["Sod / Artificial Turf"],
        "mulch": ["Mulch & Bed"], "landscape": ["Full Landscaping"],
        "drainage": ["Drainage Solutions"], "holiday lights": ["Holiday Light"],
        "christmas lights": ["Holiday Light"], "sprinkler": ["Repair & Zone"],
        "irrigation": ["New System Install", "Repair & Zone"],
        "snow": ["Snow Plowing", "Shoveling"], "ice dam": ["Ice Dam"],
        // Cleaning
        "maid": ["House Cleaning"], "deep clean": ["Deep Clean"],
        "move out": ["Move-In / Move-Out"], "junk": ["Haul-Away"],
        "haul": ["Haul-Away"], "air duct": ["Full Duct Cleaning"],
        "dryer vent": ["Dryer Vent"], "window clean": ["Window Cleaning"],
        // Auto
        "oil change": ["Oil Change"], "brakes": ["Brake Repair"],
        "detail": ["Interior Detail", "Full Detail"], "ceramic coat": ["Ceramic Coat"],
        "jump start": ["Jump Start"], "flat tire": ["Flat Tire"],
        "roadside": ["Jump Start", "Flat Tire", "Fuel Delivery"],
        // Trades
        "deck": ["Deck Build", "Deck Repair"], "pergola": ["Pergola"],
        "fence": ["Wood Fence", "Vinyl / Composite", "Chain Link"],
        "concrete": ["Concrete Repair", "New Pour"], "brick": ["Brick / Stone"],
        "stucco": ["Stucco Application"], "tile": ["Floor Tile", "Shower / Bathroom"],
        "backsplash": ["Kitchen Backsplash"], "cabinet": ["Cabinet Installation"],
        "insulation": ["Attic Insulation", "Wall / Crawlspace"],
        "spray foam": ["Spray Foam"], "roof": ["Roof Repair", "Full Roof"],
        "gutter": ["Gutter Install"], "solar": ["Solar Panel Install"],
        "siding": ["Siding Install"], "foundation": ["Crack Injection"],
        "chimney": ["Chimney Sweep"], "fireplace": ["Fireplace Insert"],
        "tree": ["Tree Trimming", "Tree Removal"], "stump": ["Stump Grinding"],
        "excavat": ["Grading & Excavation"], "grading": ["Grading & Excavation"],
        "land clear": ["Land Clearing"], "remodel": ["Kitchen Remodel", "Bathroom Remodel"],
        "renovation": ["Kitchen Remodel"], "basement": ["Basement Finish"],
        "grab bar": ["Grab Bars"], "ramp": ["Wheelchair Ramp"],
        "wheelchair": ["Wheelchair Ramp"],
        // Events & personal
        "chef": ["Private Dinner", "Full Catering"], "catering": ["Full Catering"],
        "bartender": ["Event Bartending"], "party": ["Tent & Table", "Bounce House"],
        "move": ["Full Move"], "massage": ["Swedish Massage", "Deep Tissue"],
        "yoga": ["Yoga / Pilates"], "trainer": ["Personal Training"],
        "dog walk": ["Dog Walking"], "pet sit": ["Pet Sitting"],
        "grooming": ["Mobile Grooming"], "hair": ["Haircut & Style"],
        "nails": ["Nails (Mani / Pedi)"], "makeup": ["Makeup Application"],
        "tutor": ["Academic Tutoring"], "music lesson": ["Music Lessons"],
        // Tech
        "smart home": ["Device Setup"], "wifi": ["Network / Wi-Fi"],
        "tv mount": ["TV Mount"], "sound bar": ["Sound Bar"],
        "computer repair": ["Laptop / Desktop"], "phone repair": ["Phone / Tablet"],
        "data recovery": ["Data Recovery"], "mural": ["Interior Mural"],
        // Photo
        "drone": ["Drone / Aerial"], "portrait": ["Portrait / Family"],
        "real estate photo": ["Real Estate Photography"],
        "wedding photo": ["Event Photography"],
        "video": ["Event / Wedding Video", "Promo & Brand"],
        // Real estate
        "staging": ["Full Staging Package"], "inspection": ["Full Home Inspection"],
    ]
}
