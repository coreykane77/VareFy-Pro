import SwiftUI

// MARK: - Data

struct HireService: Identifiable, Hashable {
    var id: String { label }
    let icon: String
    let label: String
    let hourlyRate: Double
    var imageName: String?        = nil
    var pitch: String?            = nil
    var portfolioImages: [String] = []  // asset names
}

struct PublicHireProfile: Hashable {
    let name: String
    let imageName: String?
    let jobsCompleted: Int
    let rating: Double
    let yearsOnPlatform: Int
    let isBoss: Bool
    let isVerified: Bool
    let bio: String
    let services: [HireService]
    let servingArea: String
    let vehicleDescription: String?
    let crewMembers: [String]
}

// MARK: - View

struct PublicProfileView: View {
    var profile: PublicHireProfile = .marcus
    var isOwnProfile: Bool = false
    @Environment(ServicesViewModel.self) private var servicesVM
    @Environment(ProfileViewModel.self) private var profileVM
    @State private var selectedService: HireService? = nil
    @State private var portfolioService: HireService? = nil

    private var displayedServices: [HireService] {
        if isOwnProfile {
            return profile.services + servicesVM.liveProfileServices
        }
        return profile.services
    }

    private var displayVehicle: String? {
        if isOwnProfile { return profileVM.profile.vehicleDescription }
        return profile.vehicleDescription
    }

    private var displayCrew: [String] {
        if isOwnProfile { return profileVM.profile.crewMembers }
        return profile.crewMembers
    }

    private var displayBio: String {
        if isOwnProfile { return profileVM.profile.bio }
        return profile.bio
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    VStack(spacing: 20) {
                        badgesRow
                        bioSection
                        servicesSection
                        servingAreaSection
                        vehicleSection
                        if !displayCrew.isEmpty {
                            crewSection
                        }
                        viewMySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            if let imageName = profile.imageName, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.varefyProCyan.opacity(0.4), lineWidth: 2))
                    .padding(.top, 20)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.varefyProCyan.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Text(String(profile.name.prefix(1)))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color.varefyProCyan)
                }
                .padding(.top, 20)
            }

            Text(profile.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            HStack(spacing: 0) {
                statPill(value: "\(profile.jobsCompleted)", label: "Jobs")
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 32)
                statPill(value: "★\(String(format: "%.1f", profile.rating))", label: "Rating")
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 32)
                statPill(value: "\(profile.yearsOnPlatform)", label: "Years")
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Badges

    private var badgesRow: some View {
        HStack(spacing: 20) {
            if profile.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
            }
            if profile.isBoss { BOSSBadge(height: 52) }
            Image(systemName: "shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.varefyProCyan)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bio

    private var bioSection: some View {
        Text(displayBio)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Services

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Services Provided")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(displayedServices, id: \.self) { service in
                        Button {
                            Haptics.light()
                            portfolioService = service
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    // Service image if available, else icon circle
                                    if let name = service.imageName,
                                       let uiImage = UIImage(named: name) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.appCard)
                                            .frame(width: 56, height: 56)
                                        Image(systemName: service.icon)
                                            .font(.title3)
                                            .foregroundStyle(Color(red: 0.76, green: 0.70, blue: 0.50))
                                    }
                                }
                                Text(service.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(width: 70, height: 28)
                                Text("$\(Int(service.hourlyRate))/hr")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.varefyProCyan)
                            }
                            .frame(width: 76)
                        }
                        .buttonStyle(.highlightRow)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)

            Text("Tap a service to view portfolio & experience")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .sheet(item: $portfolioService) { service in
            ServicePortfolioSheet(service: service)
        }
    }

    // MARK: - Serving Area

    private var servingAreaSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Serving")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(profile.servingArea)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appCard)
                    .frame(width: 100, height: 68)
                VStack(spacing: 4) {
                    Image(systemName: "map.fill")
                        .font(.title3)
                        .foregroundStyle(Color.varefyProCyan.opacity(0.5))
                    Text("Fort Worth, TX")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Vehicle

    private var vehicleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "car.fill")
                    .font(.title3)
                    .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text("VEHICLE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                    Text(displayVehicle ?? "No vehicle on file")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                Spacer()
            }
            .padding(16)

            if displayVehicle != nil, let truckImage = UIImage(named: "Ford") {
                Image(uiImage: truckImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .clipShape(
                        .rect(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 14,
                            bottomTrailingRadius: 14,
                            topTrailingRadius: 0
                        )
                    )
            }
        }
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - View My (publicly visible documents)

    private var visibleDocuments: [ProfileDocument] {
        guard isOwnProfile else { return [] }
        return profileVM.profile.documents.filter { $0.isUploaded && $0.showOnProfile }
    }

    @ViewBuilder
    private var viewMySection: some View {
        if !visibleDocuments.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                    Text("VIEW MY")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(0.8)
                }

                VStack(spacing: 0) {
                    ForEach(Array(visibleDocuments.enumerated()), id: \.element) { idx, doc in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.10))
                                    .frame(width: 40, height: 40)
                                Image(systemName: doc.category.icon)
                                    .font(.callout)
                                    .foregroundStyle(.green)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.publicTitle.isEmpty ? doc.category.rawValue : doc.publicTitle)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text("On file")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.callout)
                                .foregroundStyle(.green.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        if idx < visibleDocuments.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.leading, 62)
                        }
                    }
                }
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Crew

    private var crewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CREW")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(displayCrew, id: \.self) { member in
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                        Text(member)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Presets

extension PublicHireProfile {
    static let marcus = PublicHireProfile(
        name: "Marcus R.",
        imageName: "Marcus",
        jobsCompleted: 147,
        rating: 4.8,
        yearsOnPlatform: 2,
        isBoss: true,
        isVerified: true,
        bio: "Hey — I'm Marcus. Born and raised in Fort Worth, TX. I run Reid Pro Services and specialize in general labor, furniture assembly, and haul-away. I'm a VareFy Pro Boss member — upgraded for more visibility and priority placement, and a higher standard I hold myself to.\n\nI take pride in photo-documenting every job, showing up on time, and leaving the site better than I found it. If I can't handle something safely, I'll tell you. Weekday availability plus most Saturdays — send me a job and I'll respond fast.",
        services: [
            HireService(
                icon: "figure.strengthtraining.traditional", label: "Labor", hourlyRate: 42,
                imageName: "Handyman",
                pitch: "General labor, demo, material moving, site cleanup. I work fast and I'm not afraid of a long day. Punch-list work, renovation support, or standalone jobs — I'm on it.",
                portfolioImages: ["IMG_6859", "IMG_6860", "IMG_6861"]
            ),
            HireService(
                icon: "sofa.fill", label: "Assembly", hourlyRate: 45,
                imageName: "Furniture Assembly",
                pitch: "I've put together thousands of flat-pack pieces — IKEA, Wayfair, Amazon, all of it. I read instructions fast and I don't strip hardware. Most single-room jobs done in under two hours.",
                portfolioImages: ["IMG_6862", "IMG_6863"]
            ),
            HireService(
                icon: "trash.fill", label: "Haul-Away", hourlyRate: 48,
                imageName: "Junk removal",
                pitch: "Single-item pickups to full property cleanouts. I bring my own truck and I sort for donation, recycling, and dump. No hidden fees — you see my rate, that's what you pay.",
                portfolioImages: ["IMG_6860", "IMG_6861"]
            ),
            HireService(
                icon: "paintbrush.fill", label: "Paint", hourlyRate: 52,
                imageName: "Painting",
                pitch: "Clean lines, proper prep, no drips. I tape and protect everything before I open a can. Interior and exterior, accent walls to full rooms. I'll match your existing color or help you pick something new.",
                portfolioImages: ["IMG_6861", "IMG_6862", "IMG_6859"]
            ),
            HireService(
                icon: "wrench.and.screwdriver.fill", label: "Handy", hourlyRate: 47,
                imageName: "Handyman",
                pitch: "15 years of fixing what needs fixing. Caulking, patching, installing, adjusting — I've done it all. I show up with my own tools and I don't leave until it's right. No job too small.",
                portfolioImages: ["IMG_6863", "IMG_6859", "IMG_6860"]
            ),
        ],
        servingArea: "Fort Worth, TX\n15 mi radius",
        vehicleDescription: "2019 Ford F-250 SuperDuty",
        crewMembers: ["Doug P.", "Javier E.", "Arthur M.", "John M."]
    )

    // MARK: - Dummy Hires (H2H + Candidate Pool)

    static let diegoTorres = PublicHireProfile(
        name: "Diego T.",
        imageName: "IMG_6859",
        jobsCompleted: 83,
        rating: 4.6,
        yearsOnPlatform: 3,
        isBoss: false,
        isVerified: true,
        bio: "Diego here — I cover lawn care, edging, and general cleanup in the Arlington area. Three years in, steady clientele, always on time. I'm not Boss tier yet but I put in the same work.",
        services: [
            HireService(icon: "leaf.fill",                           label: "Lawn Care", hourlyRate: 35),
            HireService(icon: "trash.fill",                          label: "Cleanup",   hourlyRate: 30),
            HireService(icon: "figure.strengthtraining.traditional", label: "Labor",     hourlyRate: 38),
        ],
        servingArea: "Arlington, TX\n12 mi radius",
        vehicleDescription: nil,
        crewMembers: []
    )

    static let kwameWashington = PublicHireProfile(
        name: "Kwame W.",
        imageName: "IMG_6860",
        jobsCompleted: 212,
        rating: 4.9,
        yearsOnPlatform: 5,
        isBoss: true,
        isVerified: true,
        bio: "Kwame — five years running. I specialize in general labor and heavy haul. I've got the highest job count in my zone and I maintain a 4.9 because I don't cut corners. Boss member since year two.",
        services: [
            HireService(icon: "figure.strengthtraining.traditional", label: "Labor",     hourlyRate: 40),
            HireService(icon: "trash.fill",                          label: "Haul-Away", hourlyRate: 45),
            HireService(icon: "wrench.and.screwdriver.fill",         label: "Handy",     hourlyRate: 43),
        ],
        servingArea: "Fort Worth, TX\n20 mi radius",
        vehicleDescription: nil,
        crewMembers: []
    )

    static let jasonNguyen = PublicHireProfile(
        name: "Jason N.",
        imageName: "IMG_6861",
        jobsCompleted: 61,
        rating: 4.5,
        yearsOnPlatform: 1,
        isBoss: false,
        isVerified: false,
        bio: "Newer to the platform but not to the work. I've been pressure washing and doing exterior cleaning for years — just officially on VareFy Pro for the past year. Building my rep the right way.",
        services: [
            HireService(icon: "sparkles",   label: "Pressure Wash",  hourlyRate: 40),
            HireService(icon: "drop.fill",  label: "Exterior Clean", hourlyRate: 38),
        ],
        servingArea: "Grand Prairie, TX\n10 mi radius",
        vehicleDescription: nil,
        crewMembers: []
    )

    static let rasheedOkafor = PublicHireProfile(
        name: "Rasheed O.",
        imageName: "IMG_6862",
        jobsCompleted: 108,
        rating: 4.7,
        yearsOnPlatform: 4,
        isBoss: false,
        isVerified: true,
        bio: "Rasheed — four years strong. I do labor, moving help, and light demo. I'm thorough, I communicate, and I document every job with photos. 108 completed and counting.",
        services: [
            HireService(icon: "figure.strengthtraining.traditional", label: "Labor",       hourlyRate: 38),
            HireService(icon: "shippingbox.fill",                    label: "Moving Help", hourlyRate: 42),
            HireService(icon: "hammer.fill",                         label: "Light Demo",  hourlyRate: 55),
        ],
        servingArea: "Mansfield, TX\n15 mi radius",
        vehicleDescription: nil,
        crewMembers: []
    )

    static let arjunPatel = PublicHireProfile(
        name: "Arjun P.",
        imageName: "IMG_6863",
        jobsCompleted: 55,
        rating: 4.8,
        yearsOnPlatform: 2,
        isBoss: true,
        isVerified: true,
        bio: "Arjun — furniture assembly and handyman work. Went Boss after my first year because the visibility is worth it. Methodical, clean, never leave a mess. Clients rehire me consistently.",
        services: [
            HireService(icon: "sofa.fill",                   label: "Assembly", hourlyRate: 48),
            HireService(icon: "wrench.and.screwdriver.fill", label: "Handy",    hourlyRate: 50),
            HireService(icon: "paintbrush.fill",             label: "Paint",    hourlyRate: 55),
        ],
        servingArea: "Irving, TX\n12 mi radius",
        vehicleDescription: nil,
        crewMembers: []
    )

    static let allHires: [PublicHireProfile] = [
        .kwameWashington, .marcus, .rasheedOkafor, .diegoTorres, .arjunPatel, .jasonNguyen
    ]
}

// MARK: - Service Portfolio Sheet

struct ServicePortfolioSheet: View {
    let service: HireService
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Hero + service name + rate ───────────────────
                        ZStack(alignment: .bottomLeading) {
                            if let name = service.imageName,
                               let uiImage = UIImage(named: name) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                    .clipped()
                                    .overlay(Color.black.opacity(0.45))
                            } else {
                                Color.appCard
                                    .frame(height: 160)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(service.label)
                                    .font(.title2).fontWeight(.bold).foregroundStyle(.white)
                                Text("$\(Int(service.hourlyRate)) / hr")
                                    .font(.subheadline).foregroundStyle(Color.varefyProCyan)
                            }
                            .padding(16)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                        // ── Experience pitch ─────────────────────────────
                        if let pitch = service.pitch, !pitch.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Experience", systemImage: "person.text.rectangle.fill")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(.secondary).textCase(.uppercase)

                                Text(pitch)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(16)
                            .background(Color.appCard)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal, 20)
                        }

                        // ── Portfolio photos ─────────────────────────────
                        if !service.portfolioImages.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Portfolio", systemImage: "photo.stack.fill")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(.secondary).textCase(.uppercase)
                                    .padding(.horizontal, 20)

                                LazyVGrid(columns: columns, spacing: 4) {
                                    ForEach(Array(service.portfolioImages.enumerated()), id: \.offset) { _, name in
                                        if let uiImage = UIImage(named: name) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 110)
                                                .clipped()
                                        } else {
                                            Color.appCard.frame(height: 110)
                                        }
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                            }
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(service.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }
}
