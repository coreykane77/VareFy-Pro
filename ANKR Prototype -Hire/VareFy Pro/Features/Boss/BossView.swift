import SwiftUI

// MARK: - Private Models

private struct WeekEarning: Identifiable {
    let id = UUID()
    let start: String
    let end: String
    let total: Double
    let dailyAmounts: [Double] // M T W T F S S
}

private struct ServiceRank: Identifiable {
    let id = UUID()
    let name: String
    let rank: Int
    let totalInArea: Int
    let icon: String
}

private struct RepeatClient: Identifiable {
    let id = UUID()
    let initials: String
    let name: String
    let jobCount: Int
    let lastJob: String
    let isFavorited: Bool
}

private struct DemandService: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let requestCount: Int
    let avgRate: Int
}

private struct OptimizationItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    var isCompleted: Bool
}

private struct RecurringSchedule {
    var frequency: String   // "Weekly" | "Biweekly" | "Monthly"
    var dayOfWeek: Int       // 0 = Mon … 6 = Sun (used for Weekly/Biweekly)
    var dayOfMonth: Int      // 1–28 (used for Monthly)
    var time: Date

    static func defaultTime() -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - BossView

struct BossView: View {

    // MARK: Section Expand State
    @AppStorage("boss_analytics_expanded")    private var analyticsExpanded    = true
    @AppStorage("boss_visibility_expanded")   private var visibilityExpanded   = false
    @AppStorage("boss_instantpay_expanded")   private var instantPayExpanded   = false
    @AppStorage("boss_repeatclient_expanded") private var repeatClientExpanded = false
    @AppStorage("boss_demand_expanded")       private var demandExpanded       = false
    @AppStorage("boss_profile_expanded")      private var profileOptExpanded   = false

    // MARK: Subscription Sheet
    @State private var showManageSub = false
    @State private var selectedWeek: WeekEarning? = nil

    // MARK: Repeat Client Schedule State
    @State private var schedulingClientName: String? = nil
    @State private var schedules: [String: RecurringSchedule] = [
        "James M.": RecurringSchedule(frequency: "Monthly", dayOfWeek: 0, dayOfMonth: 5,  time: RecurringSchedule.defaultTime()),
        "Tanya W.": RecurringSchedule(frequency: "Biweekly", dayOfWeek: 0, dayOfMonth: 1, time: RecurringSchedule.defaultTime()),
    ]

    // MARK: Visibility Controls State
    @State private var priorityServices: Set<String> = ["Furniture Assembly", "Haul-Away"]

    // MARK: Instant Pay State
    @State private var instantPayMode: String = "manual"
    @State private var triggerThreshold: Double = 100
    @AppStorage("boss_auto_freq") private var autoFrequency: String = "weekly"

    // MARK: Profile Optimization State
    @State private var optimizationItems: [OptimizationItem] = [
        .init(title: "Add 2 more job photos",       detail: "Profiles with 8+ photos get 34% more hires",           icon: "camera.fill",                    isCompleted: false),
        .init(title: "Enable weekend availability", detail: "Weekend jobs have 2× faster hire rate",                 icon: "calendar.badge.plus",            isCompleted: false),
        .init(title: "Improve response speed",      detail: "Respond within 15 min to boost ranking",               icon: "bolt.fill",                      isCompleted: false),
        .init(title: "Add business name",           detail: "Verified business names increase trust score",          icon: "building.2.fill",                isCompleted: true),
        .init(title: "Tools confirmed on all services", detail: "Confirm tools for each enabled service",            icon: "wrench.and.screwdriver.fill",    isCompleted: true),
        .init(title: "Bio is complete",             detail: "Detailed bios improve client confidence",               icon: "text.alignleft",                 isCompleted: true),
    ]

    // MARK: Dummy Data

    private let weeklyEarnings: [WeekEarning] = [
        .init(start: "Jan 13", end: "Jan 20", total: 364.01, dailyAmounts: [80, 120, 0,  90,  74,  0,  0]),
        .init(start: "Jan 6",  end: "Jan 13", total: 329.15, dailyAmounts: [60, 110, 0,  85,  74,  0,  0]),
        .init(start: "Dec 30", end: "Jan 6",  total: 211.80, dailyAmounts: [90,   0, 0,   0,   0, 121, 0]),
        .init(start: "Dec 23", end: "Dec 30", total: 128.41, dailyAmounts: [128,  0, 0,   0,   0,  0,  0]),
        .init(start: "Dec 16", end: "Dec 23", total: 483.70, dailyAmounts: [0,  180, 0, 120, 183,  0,  0]),
        .init(start: "Dec 9",  end: "Dec 16", total: 400.34, dailyAmounts: [90, 140, 0,   0, 170,  0,  0]),
        .init(start: "Dec 2",  end: "Dec 9",  total: 292.85, dailyAmounts: [0,  110, 85,  0,   0,  0, 97]),
        .init(start: "Nov 25", end: "Dec 2",  total: 289.44, dailyAmounts: [95, 120, 0,   0,  74,  0,  0]),
    ]

    private let serviceRankings: [ServiceRank] = [
        .init(name: "Furniture Assembly", rank: 3,  totalInArea: 41, icon: "sofa.fill"),
        .init(name: "Haul-Away",          rank: 2,  totalInArea: 19, icon: "trash.fill"),
        .init(name: "General Labor",      rank: 17, totalInArea: 73, icon: "figure.strengthtraining.traditional"),
        .init(name: "Paint",             rank: 8,  totalInArea: 31, icon: "paintbrush.fill"),
        .init(name: "Handyman",          rank: 5,  totalInArea: 28, icon: "wrench.and.screwdriver.fill"),
    ]

    private let allServices: [String] = [
        "Furniture Assembly", "Haul-Away", "General Labor",
        "Paint", "Handyman", "Pressure Washing", "Lawn Care", "Drywall Repair",
    ]

    private let repeatClients: [RepeatClient] = [
        .init(initials: "JM", name: "James M.",  jobCount: 8, lastJob: "Jan 15",  isFavorited: true),
        .init(initials: "TW", name: "Tanya W.",  jobCount: 5, lastJob: "Jan 8",   isFavorited: true),
        .init(initials: "RB", name: "Robert B.", jobCount: 3, lastJob: "Dec 30",  isFavorited: false),
        .init(initials: "SL", name: "Sophia L.", jobCount: 3, lastJob: "Dec 20",  isFavorited: true),
    ]

    private let demandServices: [DemandService] = [
        .init(rank: 1, name: "Furniture Assembly", requestCount: 143, avgRate: 46),
        .init(rank: 2, name: "Pressure Washing",   requestCount: 118, avgRate: 41),
        .init(rank: 3, name: "TV Mounting",        requestCount: 97,  avgRate: 38),
        .init(rank: 4, name: "Haul-Away",          requestCount: 89,  avgRate: 44),
        .init(rank: 5, name: "Lawn Maintenance",   requestCount: 82,  avgRate: 35),
        .init(rank: 6, name: "House Cleaning",     requestCount: 76,  avgRate: 32),
        .init(rank: 7, name: "General Labor",      requestCount: 71,  avgRate: 38),
        .init(rank: 8, name: "Painting",           requestCount: 65,  avgRate: 50),
    ]

    // MARK: Computed

    private var completedCount: Int { optimizationItems.filter { $0.isCompleted }.count }
    private var optimizationScore: Int { Int(Double(completedCount) / Double(optimizationItems.count) * 100) }
    private var scoreColor: Color {
        switch optimizationScore {
        case 80...100: return Color.varefyProCyan
        case 50..<80:  return Color.varefyProGold
        default:       return .orange
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            List {
                analyticsSection
                visibilitySection
                instantPaySection
                repeatClientSection
                demandSection
                profileOptSection
                subscriptionSection
            }
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, 100, for: .scrollContent)
        }
        .sheet(isPresented: $showManageSub) {
            ManageSubscriptionSheet()
        }
        .sheet(item: $selectedWeek) { week in
            WeekDetailSheet(week: week)
        }
        .sheet(item: Binding(
            get: { schedulingClientName.map { SchedulingTarget(name: $0) } },
            set: { schedulingClientName = $0?.name }
        )) { target in
            RecurringScheduleEditor(
                clientName: target.name,
                schedule: Binding(
                    get: { schedules[target.name] ?? RecurringSchedule(frequency: "Monthly", dayOfWeek: 0, dayOfMonth: 1, time: RecurringSchedule.defaultTime()) },
                    set: { schedules[target.name] = $0 }
                )
            )
        }
        .navigationTitle("Boss Controls")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
    }

    // MARK: - Section 1: Boss Analytics

    private var analyticsSection: some View {
        Section {
            if analyticsExpanded {
                // Summary stats
                HStack(spacing: 0) {
                    statCell(value: "$2,499", label: "This Month")
                    Divider().frame(height: 36)
                    statCell(value: "147",    label: "Total Jobs")
                    Divider().frame(height: 36)
                    statCell(value: "★ 4.8",  label: "Rating", color: Color.varefyProGold)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)

                // Weekly earnings list
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("WEEKLY EARNINGS")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                                Text(d)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 16)
                            }
                        }
                    }
                    .padding(.bottom, 12)

                    ForEach(weeklyEarnings) { week in
                        Button {
                            Haptics.light()
                            selectedWeek = week
                        } label: {
                            weekRow(week)
                        }
                        .buttonStyle(.highlightRow)
                        if week.id != weeklyEarnings.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
                .padding(.vertical, 12)
                .listRowBackground(Color.appCard)

                // Service performance rankings
                VStack(alignment: .leading, spacing: 10) {
                    Text("SERVICE PERFORMANCE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(serviceRankings) { item in
                        serviceRankRow(item)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)
            }
        } header: {
            sectionHeader(
                "Boss Analytics",
                badge: "$2,499 this month",
                badgeColor: .varefyProCyan,
                isExpanded: analyticsExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { analyticsExpanded.toggle() }
            }
        }
    }

    @ViewBuilder
    private func statCell(value: String, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func serviceRankRow(_ item: ServiceRank) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.caption)
                .foregroundStyle(rankColor(item.rank))
                .frame(width: 20)

            Text(item.name)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 4) {
                Text("#\(item.rank)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(rankColor(item.rank))
                Text("of \(item.totalInArea)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:  return Color.varefyProGold
        case 2:  return Color(red: 0.75, green: 0.75, blue: 0.78)
        case 3:  return Color(red: 0.80, green: 0.50, blue: 0.25)
        default: return Color.varefyProCyan
        }
    }

    @ViewBuilder
    private func weekRow(_ week: WeekEarning) -> some View {
        let maxAmt = week.dailyAmounts.max() ?? 1
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(week.start) – \(week.end)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(Int(week.total.rounded()))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            HStack(spacing: 0) {
                ForEach(Array(week.dailyAmounts.enumerated()), id: \.offset) { _, amt in
                    let barH = amt > 0 ? max(4, CGFloat(amt / maxAmt) * 28) : 2
                    RoundedRectangle(cornerRadius: 2)
                        .fill(amt > 0 ? Color.varefyProCyan : Color.white.opacity(0.08))
                        .frame(width: 10, height: barH)
                        .frame(width: 16, height: 28, alignment: .bottom)
                }
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Section 2: Visibility Controls

    private var visibilitySection: some View {
        Section {
            if visibilityExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose up to 2 services for priority placement. These appear first in search results and job matching.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(allServices, id: \.self) { service in
                        let isSelected = priorityServices.contains(service)
                        let atMax = priorityServices.count >= 2 && !isSelected

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                if isSelected {
                                    priorityServices.remove(service)
                                } else if !atMax {
                                    priorityServices.insert(service)
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isSelected ? Color.varefyProCyan : Color(UIColor.secondaryLabel))
                                    .opacity(atMax && !isSelected ? 0.3 : 1.0)

                                Text(service)
                                    .font(.subheadline)
                                    .foregroundStyle(isSelected ? .primary : (atMax ? .secondary : .primary))
                                    .opacity(atMax && !isSelected ? 0.5 : 1.0)

                                Spacer()

                                if isSelected {
                                    Text("Priority")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.varefyProCyan)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .buttonStyle(.highlightRow)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)
            }
        } header: {
            sectionHeader(
                "Visibility Controls",
                badge: "\(priorityServices.count)/2 selected",
                badgeColor: .varefyProCyan,
                isExpanded: visibilityExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { visibilityExpanded.toggle() }
            }
        } footer: {
            if visibilityExpanded {
                Text("Boss members receive priority ranking in 2 service categories. Changes apply within 24 hours.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Section 3: Instant Pay Control Center

    private var instantPaySection: some View {
        Section {
            if instantPayExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Text("PAYOUT MODE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        modeButton("Manual", value: "manual", icon: "hand.tap.fill")
                        modeButton("Auto",   value: "auto",   icon: "arrow.clockwise.circle.fill")
                    }

                    if instantPayMode == "auto" {
                        Divider().background(Color.white.opacity(0.08))

                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundStyle(Color.varefyProCyan)
                                    .frame(width: 22)
                                Text("Auto-trigger Threshold")
                                    .font(.subheadline)
                                Spacer()
                                Text("$\(Int(triggerThreshold))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.varefyProCyan)
                                    .monospacedDigit()
                                    .frame(width: 52, alignment: .trailing)
                            }
                            Slider(value: $triggerThreshold, in: 25...500, step: 25)
                                .tint(Color.varefyProCyan)
                                .padding(.leading, 28)
                            Text("Balance above this amount triggers an instant payout automatically.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 28)
                        }

                        Divider().background(Color.white.opacity(0.08))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundStyle(Color.varefyProCyan)
                                    .frame(width: 22)
                                Text("Auto Schedule")
                                    .font(.subheadline)
                            }
                            HStack(spacing: 8) {
                                ForEach(["daily", "weekly", "biweekly"], id: \.self) { freq in
                                    Button {
                                        autoFrequency = freq
                                    } label: {
                                        Text(freq.capitalized)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(autoFrequency == freq ? .black : .primary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(autoFrequency == freq ? Color.varefyProCyan : Color.appBackground)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.highlightRow)
                                }
                            }
                            .padding(.leading, 28)
                        }
                    } else {
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                            Text("Manual mode — initiate payouts from Wallet when ready. 1.5% Instant Pay fee applies per payout.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)

                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Color.varefyProGold)
                        .font(.caption)
                    Text("Instant Pay is exclusive to Boss members. 1.5% fee per payout. Bank transfer always free.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 6)
                .listRowBackground(Color.appCard)
            }
        } header: {
            sectionHeader(
                "Instant Pay Center",
                badge: instantPayMode == "auto" ? "Auto · $\(Int(triggerThreshold))" : "Manual",
                badgeColor: instantPayMode == "auto" ? .varefyProCyan : .secondary,
                isExpanded: instantPayExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { instantPayExpanded.toggle() }
            }
        }
    }

    @ViewBuilder
    private func modeButton(_ label: String, value: String, icon: String) -> some View {
        let isSelected = instantPayMode == value
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                instantPayMode = value
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .black : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.varefyProCyan : Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: - Section 4: Repeat Client Tools

    private var repeatClientSection: some View {
        Section {
            if repeatClientExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FAVORITED CLIENTS")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(repeatClients) { client in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.varefyProCyan.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Text(client.initials)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.varefyProCyan)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text(client.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if client.isFavorited {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.varefyProGold)
                                    }
                                }
                                Text("\(client.jobCount) jobs · Last: \(client.lastJob)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                Haptics.light()
                                schedulingClientName = client.name
                            } label: {
                                Text(schedules[client.name] != nil ? "Edit" : "Schedule")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.varefyProCyan)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.highlightRow)
                        }
                        .padding(.vertical, 3)

                        if client.id != repeatClients.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)

                HStack(spacing: 12) {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Recurring Job Scheduler")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Set up weekly or biweekly recurring jobs with repeat clients. Coming to Boss tier soon.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)
            }
        } header: {
            sectionHeader(
                "Repeat Client Tools",
                badge: "\(repeatClients.filter { $0.isFavorited }.count) favorited",
                badgeColor: Color.varefyProGold,
                isExpanded: repeatClientExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { repeatClientExpanded.toggle() }
            }
        }
    }

    // MARK: - Section 5: Demand Insights

    private var demandSection: some View {
        Section {
            if demandExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MOST REQUESTED IN YOUR AREA")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    ForEach(demandServices) { item in
                        HStack(spacing: 12) {
                            Text("#\(item.rank)")
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundStyle(item.rank <= 3 ? Color.varefyProCyan : .secondary)
                                .frame(width: 24, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text("\(item.requestCount) requests this month")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 1) {
                                Text("$\(item.avgRate)/hr")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.varefyProCyan)
                                Text("avg")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.vertical, 4)

                        if item.id != demandServices.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)
            }
        } header: {
            sectionHeader(
                "Demand Insights",
                badge: "8 services tracked",
                badgeColor: .varefyProCyan,
                isExpanded: demandExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { demandExpanded.toggle() }
            }
        } footer: {
            if demandExpanded {
                Text("Based on job requests in your 25 mi radius over the last 30 days. Avg rates reflect accepted bids — use these to price competitively.")
                    .font(.caption)
            }
        }
    }

    // MARK: - Section 6: Profile Optimization

    private var profileOptSection: some View {
        Section {
            if profileOptExpanded {
                // Score ring
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: CGFloat(optimizationScore) / 100)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 0.5), value: optimizationScore)
                    }
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text("\(optimizationScore)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(scoreColor)
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Profile Score")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("\(completedCount) of \(optimizationItems.count) optimizations complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.appCard)

                // Checklist
                ForEach(optimizationItems.indices, id: \.self) { i in
                    let item = optimizationItems[i]
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            optimizationItems[i].isCompleted.toggle()
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(item.isCompleted ? Color.varefyProCyan : .secondary.opacity(0.4))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                                    .strikethrough(item.isCompleted, color: .secondary)
                                Text(item.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(item.isCompleted ? 0.5 : 1.0))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.highlightRow)
                    .listRowBackground(Color.appCard)
                }
            }
        } header: {
            sectionHeader(
                "Profile Optimization",
                badge: "\(optimizationScore)% optimized",
                badgeColor: scoreColor,
                isExpanded: profileOptExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.22)) { profileOptExpanded.toggle() }
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section {
            VStack(spacing: 14) {
                // Status row
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.varefyProCyan.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "shield.fill")
                            .font(.title3)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Boss Plan")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Text("ACTIVE")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.varefyProCyan)
                                .clipShape(Capsule())
                        }
                        Text("Renews Feb 7, 2026 · $34.99/mo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.08))

                // Manage button
                Button {
                    showManageSub = true
                } label: {
                    Text("Manage Subscription")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.highlightRow)
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.appCard)
        } header: {
            Text("YOUR PLAN")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Section Header Helper

    @ViewBuilder
    private func sectionHeader(
        _ title: String,
        badge: String? = nil,
        badgeColor: Color = .varefyProCyan,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Text(title)
                    .foregroundStyle(isExpanded ? Color.varefyProCyan : Color(UIColor.secondaryLabel))
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(badgeColor)
                        .textCase(.none)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.varefyProCyan)
                    .rotationEffect(isExpanded ? .degrees(0) : .degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .buttonStyle(.highlightRow)
    }
}

// MARK: - Manage Subscription Sheet

private struct ManageSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Plan card
                    VStack(spacing: 16) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.varefyProCyan)

                        VStack(spacing: 6) {
                            Text("Boss Plan")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("$34.99 / month")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Renews Feb 7, 2026 · $34.99/mo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Info
                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(icon: "checkmark.circle.fill", color: .green,          text: "Priority placement in 2 service categories")
                        infoRow(icon: "checkmark.circle.fill", color: .green,          text: "Instant Pay access")
                        infoRow(icon: "checkmark.circle.fill", color: .green,          text: "Boss Analytics & Demand Insights")
                        infoRow(icon: "checkmark.circle.fill", color: .green,          text: "Repeat Client scheduling tools")
                        infoRow(icon: "checkmark.circle.fill", color: .green,          text: "Profile Optimization score")
                    }
                    .padding(16)
                    .background(Color.appCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer()

                    // Cancel note
                    VStack(spacing: 8) {
                        Text("Subscriptions are managed through the App Store.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            // In production: open itms-apps:// subscription management
                        } label: {
                            Text("Cancel Subscription")
                                .font(.subheadline)
                                .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.highlightRow)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Manage Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Week Detail Sheet

private struct WeekDetailSheet: View {
    let week: WeekEarning
    @Environment(\.dismiss) private var dismiss

    private let dayLabels = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // Total card
                        VStack(spacing: 6) {
                            Text("\(week.start) – \(week.end)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .tracking(0.6)
                            Text("$\(Int(week.total.rounded()))")
                                .font(.system(size: 42, weight: .heavy))
                                .foregroundStyle(.primary)
                            Text("Total Earned")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(LinearGradient(
                            colors: [Color.varefyProCyan.opacity(0.2), Color.appCard],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Day breakdown
                        let maxAmt = week.dailyAmounts.max() ?? 1
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DAILY BREAKDOWN")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 12)

                            ForEach(dayLabels.indices, id: \.self) { i in
                                let amt = week.dailyAmounts[i]
                                HStack(spacing: 12) {
                                    Text(dayLabels[i])
                                        .font(.subheadline)
                                        .foregroundStyle(amt > 0 ? .primary : .secondary)
                                        .frame(width: 90, alignment: .leading)

                                    GeometryReader { geo in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(amt > 0 ? Color.varefyProCyan : Color.white.opacity(0.06))
                                            .frame(width: amt > 0 ? max(6, geo.size.width * CGFloat(amt / maxAmt)) : 6)
                                            .frame(maxHeight: .infinity)
                                    }
                                    .frame(height: 22)

                                    Text(amt > 0 ? "$\(Int(amt.rounded()))" : "—")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(amt > 0 ? Color.varefyProCyan : .secondary)
                                        .frame(width: 64, alignment: .trailing)
                                }
                                .padding(.vertical, 10)
                                if i < dayLabels.count - 1 {
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Weekly Earnings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }
}

// MARK: - Sheet Identity Helper

private struct SchedulingTarget: Identifiable {
    let name: String
    var id: String { name }
}

// MARK: - Recurring Schedule Editor Sheet

private struct RecurringScheduleEditor: View {
    let clientName: String
    @Binding var schedule: RecurringSchedule
    @Environment(\.dismiss) private var dismiss

    private let frequencies = ["Weekly", "Biweekly", "Monthly"]
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                List {
                    // Client header
                    Section {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.varefyProCyan.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Text(String(clientName.prefix(2)).uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.varefyProCyan)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(clientName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Recurring job schedule")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.appCard)
                    }

                    // Frequency
                    Section("Frequency") {
                        HStack(spacing: 8) {
                            ForEach(frequencies, id: \.self) { freq in
                                Button {
                                    Haptics.light()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        schedule.frequency = freq
                                    }
                                } label: {
                                    Text(freq)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(schedule.frequency == freq ? .black : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(schedule.frequency == freq ? Color.varefyProCyan : Color.appBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.highlightRow)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.appCard)
                    }

                    // Day selector
                    if schedule.frequency == "Monthly" {
                        Section("Day of Month") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Repeat on the \(ordinal(schedule.dayOfMonth)) of each month")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                // Day grid: 1–28 in rows of 7
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                    ForEach(1...28, id: \.self) { day in
                                        Button {
                                            Haptics.light()
                                            schedule.dayOfMonth = day
                                        } label: {
                                            Text("\(day)")
                                                .font(.caption)
                                                .fontWeight(schedule.dayOfMonth == day ? .bold : .regular)
                                                .foregroundStyle(schedule.dayOfMonth == day ? .black : .primary)
                                                .frame(maxWidth: .infinity, minHeight: 32)
                                                .background(schedule.dayOfMonth == day ? Color.varefyProCyan : Color.appBackground)
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                        }
                                        .buttonStyle(.highlightRow)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(Color.appCard)
                        }
                    } else {
                        Section("Day of Week") {
                            HStack(spacing: 6) {
                                ForEach(weekdays.indices, id: \.self) { i in
                                    Button {
                                        Haptics.light()
                                        schedule.dayOfWeek = i
                                    } label: {
                                        Text(weekdays[i])
                                            .font(.caption2)
                                            .fontWeight(schedule.dayOfWeek == i ? .bold : .regular)
                                            .foregroundStyle(schedule.dayOfWeek == i ? .black : .primary)
                                            .frame(maxWidth: .infinity, minHeight: 34)
                                            .background(schedule.dayOfWeek == i ? Color.varefyProCyan : Color.appBackground)
                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                    }
                                    .buttonStyle(.highlightRow)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.appCard)
                        }
                    }

                    // Time
                    Section("Time") {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(Color.varefyProCyan)
                                .frame(width: 22)
                            Text("Start time")
                                .font(.subheadline)
                            Spacer()
                            DatePicker("", selection: $schedule.time, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .tint(Color.varefyProCyan)
                        }
                        .listRowBackground(Color.appCard)
                    }

                    // Summary
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                .foregroundStyle(Color.varefyProCyan)
                            Text(scheduleSummary)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.varefyProCyan.opacity(0.1))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Recurring Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appNavBar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Haptics.medium()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }

    private var scheduleSummary: String {
        let timeStr = schedule.time.formatted(Date.FormatStyle().hour().minute())
        switch schedule.frequency {
        case "Monthly":
            return "Repeats on the \(ordinal(schedule.dayOfMonth)) of each month at \(timeStr)"
        case "Biweekly":
            return "Repeats every other \(["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"][schedule.dayOfWeek]) at \(timeStr)"
        default:
            return "Repeats every \(["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"][schedule.dayOfWeek]) at \(timeStr)"
        }
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n % 10 {
        case 1 where n % 100 != 11: suffix = "st"
        case 2 where n % 100 != 12: suffix = "nd"
        case 3 where n % 100 != 13: suffix = "rd"
        default: suffix = "th"
        }
        return "\(n)\(suffix)"
    }
}
