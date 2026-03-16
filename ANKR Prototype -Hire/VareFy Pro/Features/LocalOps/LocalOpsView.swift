import SwiftUI

// MARK: - Data Model

struct LocalOpListing: Identifiable {
    let id = UUID()
    let serviceType: String
    let description: String
    let candidateCount: Int
    let isFavorited: Bool
    let postedAgo: String
    let distanceMiles: Double
}

// MARK: - Candidate Pool Model

struct CandidateHire: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String?
    let specialty: String
    let rating: Double
    let jobsCompleted: Int
    let isBoss: Bool
    let isYou: Bool
    let isFavorited: Bool
}

// MARK: - View

struct LocalOpsView: View {
    @State private var searchRadius: Double = 15
    @State private var selectedListing: LocalOpListing? = nil

    private let listings: [LocalOpListing] = [
        LocalOpListing(serviceType: "Lawn Care",
                       description: "Large backyard mowing, edging, and leaf debris cleanup. Approximately half acre. Client has equipment on site.",
                       candidateCount: 4,
                       isFavorited: true,
                       postedAgo: "12 min ago",
                       distanceMiles: 2.3),
        LocalOpListing(serviceType: "Pressure Washing",
                       description: "Two-car driveway and back patio. Client can provide equipment or hire can bring their own.",
                       candidateCount: 7,
                       isFavorited: false,
                       postedAgo: "34 min ago",
                       distanceMiles: 4.1),
        LocalOpListing(serviceType: "Furniture Assembly",
                       description: "IKEA bedroom set — bed frame, dresser, and two nightstands. Instructions on site. Second floor, elevator available.",
                       candidateCount: 2,
                       isFavorited: true,
                       postedAgo: "1 hr ago",
                       distanceMiles: 6.7),
        LocalOpListing(serviceType: "General Labor",
                       description: "Moving boxes from a 10x10 storage unit to second floor apartment. About 40 boxes, some heavier items.",
                       candidateCount: 9,
                       isFavorited: false,
                       postedAgo: "2 hrs ago",
                       distanceMiles: 3.5),
        LocalOpListing(serviceType: "Window Cleaning",
                       description: "Interior and exterior windows on a single-story 3-bedroom home. Cleaning solution provided by client.",
                       candidateCount: 3,
                       isFavorited: false,
                       postedAgo: "3 hrs ago",
                       distanceMiles: 8.2),
        LocalOpListing(serviceType: "Gutter Cleaning",
                       description: "Single story home, approximately 150 linear feet of gutter. Ladder required — client does not have one.",
                       candidateCount: 5,
                       isFavorited: false,
                       postedAgo: "4 hrs ago",
                       distanceMiles: 11.0),
        LocalOpListing(serviceType: "Interior Painting",
                       description: "Master bedroom and connecting hallway. Paint and supplies provided by client. One coat needed.",
                       candidateCount: 6,
                       isFavorited: true,
                       postedAgo: "5 hrs ago",
                       distanceMiles: 9.4),
    ]

    private var filteredListings: [LocalOpListing] {
        listings.filter { $0.distanceMiles <= searchRadius }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                radiusControl
                listContent
            }
        }
        .navigationTitle("Local Ops")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
        .sheet(item: $selectedListing) { listing in
            CandidatePoolSheet(listing: listing)
        }
    }

    // MARK: - Radius Slider

    private var radiusControl: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "scope")
                    .foregroundStyle(Color.varefyProCyan)
                    .font(.subheadline)
                Text("Search Radius")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(Int(searchRadius)) mi")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.varefyProCyan)
                    .frame(minWidth: 44, alignment: .trailing)
            }

            Slider(value: $searchRadius, in: 5...50, step: 1)
                .tint(Color.varefyProCyan)

            HStack {
                Text("5 mi")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("50 mi")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(filteredListings.count) open request\(filteredListings.count == 1 ? "" : "s") in range")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.appCard)
    }

    // MARK: - Listings

    private var listContent: some View {
        ScrollView {
            if filteredListings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.varefyProCyan.opacity(0.4))
                    Text("No open requests in range")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Expand your search radius to see more.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 80)
                .padding(.horizontal, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredListings) { listing in
                        LocalOpCard(listing: listing) {
                            selectedListing = listing
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
        }
    }
}

// MARK: - Local Op Card

struct LocalOpCard: View {
    let listing: LocalOpListing
    let onReviewCandidates: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(listing.serviceType)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if listing.isFavorited {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text("Favorited")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(Color.varefyProGold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.varefyProGold.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 8) {
                        Label(listing.postedAgo, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 3) {
                            Image(systemName: "location.fill")
                                .font(.footnote)
                            Text(String(format: "%.1f mi", listing.distanceMiles))
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            // Description
            Text(listing.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Divider().background(Color.white.opacity(0.08))

            // Footer row
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(listing.candidateCount) in pool")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onReviewCandidates) {
                    Text("Review Candidates")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.varefyProCyan.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Candidate Pool Sheet

struct CandidatePoolSheet: View {
    let listing: LocalOpListing
    @Environment(\.dismiss) private var dismiss

    private let candidates: [CandidateHire] = [
        CandidateHire(name: "Marcus Reid",   imageName: "Marcus",    specialty: "General Labor",      rating: 4.8, jobsCompleted: 147, isBoss: true,  isYou: true,  isFavorited: true),
        CandidateHire(name: "Kwame W.",      imageName: "IMG_6860",  specialty: "General Labor",      rating: 4.9, jobsCompleted: 212, isBoss: true,  isYou: false, isFavorited: false),
        CandidateHire(name: "Rasheed O.",    imageName: "IMG_6862",  specialty: "Labor & Moving",     rating: 4.7, jobsCompleted: 108, isBoss: false, isYou: false, isFavorited: false),
        CandidateHire(name: "Diego T.",      imageName: "IMG_6859",  specialty: "Lawn & Landscape",   rating: 4.6, jobsCompleted: 83,  isBoss: false, isYou: false, isFavorited: true),
        CandidateHire(name: "Arjun P.",      imageName: "IMG_6863",  specialty: "Furniture Assembly", rating: 4.8, jobsCompleted: 55,  isBoss: true,  isYou: false, isFavorited: false),
        CandidateHire(name: "Jason N.",      imageName: "IMG_6861",  specialty: "Pressure Washing",   rating: 4.5, jobsCompleted: 61,  isBoss: false, isYou: false, isFavorited: false),
        CandidateHire(name: "T. Marshall",   imageName: nil,         specialty: "General Labor",      rating: 4.4, jobsCompleted: 39,  isBoss: false, isYou: false, isFavorited: false),
        CandidateHire(name: "C. Simmons",    imageName: nil,         specialty: "Lawn & Landscape",   rating: 4.6, jobsCompleted: 94,  isBoss: false, isYou: false, isFavorited: false),
        CandidateHire(name: "M. Johnson",    imageName: nil,         specialty: "General Labor",      rating: 4.3, jobsCompleted: 28,  isBoss: false, isYou: false, isFavorited: false),
    ]

    private var visibleCandidates: [CandidateHire] {
        Array(candidates.prefix(listing.candidateCount))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Job context header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(listing.serviceType)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(listing.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.varefyProCyan)
                                Text("\(listing.candidateCount) hires in this pool")
                                    .font(.caption)
                                    .foregroundStyle(Color.varefyProCyan)
                            }
                            .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.appCard)

                        Text("CANDIDATE POOL")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundStyle(.secondary)
                            .tracking(1.2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                            .padding(.bottom, 8)

                        LazyVStack(spacing: 1) {
                            ForEach(visibleCandidates) { candidate in
                                CandidateRow(candidate: candidate)
                            }
                        }
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 16)

                        Text("Client selection is anonymous. You cannot contact or identify the client until selected.")
                            .font(.caption2)
                            .foregroundStyle(.secondary.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Candidate Pool")
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

// MARK: - Candidate Row

struct CandidateRow: View {
    let candidate: CandidateHire

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                if let imageName = candidate.imageName, let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(
                            candidate.isYou ? Color.varefyProCyan.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        ))
                } else {
                    Circle()
                        .fill(Color.varefyProCyan.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Text(candidate.name.prefix(1))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(candidate.isYou ? candidate.name : candidate.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    if candidate.isYou {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.varefyProCyan.opacity(0.18))
                            .foregroundStyle(Color.varefyProCyan)
                            .clipShape(Capsule())
                    }
                    if candidate.isBoss { BOSSBadge() }
                }
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.varefyProGold)
                        Text(String(format: "%.1f", candidate.rating))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("·")
                        .foregroundStyle(.secondary.opacity(0.4))
                    Text("\(candidate.jobsCompleted) jobs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if candidate.isFavorited {
                Image(systemName: "star.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.varefyProGold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(candidate.isYou ? Color.varefyProCyan.opacity(0.06) : Color.clear)
    }
}
