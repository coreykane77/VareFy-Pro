import SwiftUI

// MARK: - Models

private struct DaySchedule: Identifiable {
    var id: Int { dayIndex }
    let dayIndex: Int
    let name: String
    let abbrev: String
    var isOn: Bool
    var startTime: Date
    var endTime: Date
    var isExpanded: Bool = false

    private static func clock(_ hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }

    var timeLabel: String {
        "\(startTime.formatted(Date.FormatStyle().hour().minute())) – \(endTime.formatted(Date.FormatStyle().hour().minute()))"
    }

    init(dayIndex: Int, name: String, abbrev: String, isOn: Bool,
         startHour: Int = 8, endHour: Int = 18) {
        self.dayIndex  = dayIndex
        self.name      = name
        self.abbrev    = abbrev
        self.isOn      = isOn
        self.startTime = DaySchedule.clock(startHour)
        self.endTime   = DaySchedule.clock(endHour)
    }
}

private struct BlockedRange: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date

    var label: String {
        let cal = Calendar.current
        let fmt = Date.FormatStyle().month(.abbreviated).day()
        if cal.isDate(start, inSameDayAs: end) {
            return start.formatted(fmt)
        } else if cal.component(.month, from: start) == cal.component(.month, from: end) {
            return "\(start.formatted(fmt)) – \(cal.component(.day, from: end))"
        } else {
            return "\(start.formatted(fmt)) – \(end.formatted(fmt))"
        }
    }
}

// MARK: - FieldControlView

struct FieldControlView: View {

    // MARK: Weekly Schedule State
    @State private var schedule: [DaySchedule] = [
        .init(dayIndex: 0, name: "Monday",    abbrev: "Mon", isOn: true),
        .init(dayIndex: 1, name: "Tuesday",   abbrev: "Tue", isOn: true),
        .init(dayIndex: 2, name: "Wednesday", abbrev: "Wed", isOn: true),
        .init(dayIndex: 3, name: "Thursday",  abbrev: "Thu", isOn: true),
        .init(dayIndex: 4, name: "Friday",    abbrev: "Fri", isOn: true),
        .init(dayIndex: 5, name: "Saturday",  abbrev: "Sat", isOn: false),
        .init(dayIndex: 6, name: "Sunday",    abbrev: "Sun", isOn: false),
    ]

    // MARK: Calendar / Date Overrides State
    @State private var displayedMonth: Date = {
        let comps = Calendar.current.dateComponents([.year, .month], from: Date())
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var blockedRanges: [BlockedRange] = []
    @State private var rangeStart: Date? = nil

    // MARK: Job Filter State
    @AppStorage("fc_service_radius") private var serviceRadius: Double = 25
    @AppStorage("fc_max_distance")   private var maxDistance: Double = 50

    // MARK: Preferences State
    @AppStorage("fc_min_rating") private var minRating: Int = 0   // 0 = Any

    // MARK: Calendar Sync State (mutually exclusive — only one at a time)
    @State private var connectedCalendar: String? = nil   // "google" | "outlook" | "apple" | nil

    // MARK: Section Collapse State (persisted via AppStorage)
    @AppStorage("fc_weekly_expanded")       private var weeklyExpanded        = false
    @AppStorage("fc_date_overrides_expanded") private var dateOverridesExpanded = false
    @AppStorage("fc_cal_sync_expanded")     private var calSyncExpanded       = false
    @AppStorage("fc_job_filters_expanded")  private var jobFiltersExpanded    = false
    @AppStorage("fc_prefs_expanded")        private var prefsExpanded         = false

    // MARK: Derived

    private var enabledCount: Int { schedule.filter { $0.isOn }.count }

    private var scheduleIsConsistent: Bool {
        let active = schedule.filter { $0.isOn }
        guard active.count > 1 else { return false }
        let cal = Calendar.current
        let ref = active[0]
        return active.dropFirst().allSatisfy {
            cal.component(.hour, from: $0.startTime) == cal.component(.hour, from: ref.startTime) &&
            cal.component(.hour, from: $0.endTime)   == cal.component(.hour, from: ref.endTime)
        }
    }

    private var connectedCalCount: Int { connectedCalendar != nil ? 1 : 0 }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            List {

                // MARK: Services Section
                Section {
                    NavigationLink(value: NavRoute.myServices) {
                        HStack(spacing: 12) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundStyle(Color.varefyProCyan)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("My Services")
                                    .foregroundStyle(.primary)
                                Text("Manage offerings, rates & tool confirmations")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Services")
                }

                // MARK: Weekly Schedule Section
                Section {
                    if weeklyExpanded {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                quickSetButton("Weekdays") { applyDays([0, 1, 2, 3, 4]) }
                                quickSetButton("Weekends") { applyDays([5, 6]) }
                                quickSetButton("All Week") { applyDays([0, 1, 2, 3, 4, 5, 6]) }
                                quickSetButton("Clear All") { applyDays([]) }
                            }
                            .padding(.trailing, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

                        ForEach(schedule.indices, id: \.self) { i in
                            dayRow(index: i)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                } header: {
                    sectionHeader(
                        "Weekly Schedule",
                        badge: enabledCount > 0
                            ? "\(enabledCount) day\(enabledCount == 1 ? "" : "s")\(scheduleIsConsistent ? " · Consistent" : "")"
                            : nil,
                        badgeColor: .varefyProCyan,
                        isExpanded: weeklyExpanded
                    ) {
                        withAnimation(.easeInOut(duration: 0.22)) { weeklyExpanded.toggle() }
                    }
                } footer: {
                    if weeklyExpanded {
                        Text("Tap a day's hours to adjust start and end times. Use \"Apply to all\" to sync hours across active days.")
                            .font(.caption)
                    }
                }

                // MARK: Date Overrides Section
                Section {
                    if dateOverridesExpanded {
                        VStack(spacing: 14) {

                            // Month navigation
                            HStack {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { shiftMonth(-1) }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 34, height: 34)
                                        .background(Color.appBackground)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.highlightRow)

                                Spacer()
                                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { shiftMonth(1) }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .frame(width: 34, height: 34)
                                        .background(Color.appBackground)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.highlightRow)
                            }

                            // Day-of-week headers
                            HStack(spacing: 0) {
                                ForEach(["S","M","T","W","T","F","S"], id: \.self) { wd in
                                    Text(wd)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.tertiary)
                                        .frame(maxWidth: .infinity)
                                }
                            }

                            // Calendar grid
                            VStack(spacing: 2) {
                                ForEach(Array(calendarWeeks().enumerated()), id: \.offset) { _, week in
                                    HStack(spacing: 2) {
                                        ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                                            if let date = date {
                                                dayCellView(date)
                                            } else {
                                                Color.clear.frame(maxWidth: .infinity, minHeight: 32)
                                            }
                                        }
                                    }
                                }
                            }

                            // Blocked range chips
                            if !blockedRanges.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Divider()
                                    Text("Blocked")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(blockedRanges.sorted { $0.start < $1.start }) { range in
                                                HStack(spacing: 5) {
                                                    Text(range.label)
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                        .foregroundStyle(.white)
                                                    Button {
                                                        withAnimation(.easeInOut(duration: 0.18)) {
                                                            blockedRanges.removeAll { $0.id == range.id }
                                                        }
                                                    } label: {
                                                        Image(systemName: "xmark")
                                                            .font(.system(size: 9, weight: .bold))
                                                            .foregroundStyle(.white.opacity(0.75))
                                                    }
                                                    .buttonStyle(.highlightRow)
                                                }
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(Color.red.opacity(0.65))
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }

                            // In-progress hint
                            if rangeStart != nil {
                                HStack(spacing: 6) {
                                    Image(systemName: "hand.tap.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.varefyProCyan)
                                    Text("Tap a second date to block the range, or tap the same date again for a single day.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(16)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.appCard)
                    }
                } header: {
                    sectionHeader(
                        "Date Overrides",
                        badge: blockedRanges.isEmpty ? nil
                            : "\(blockedRanges.count) block\(blockedRanges.count == 1 ? "" : "s")",
                        badgeColor: .red,
                        isExpanded: dateOverridesExpanded
                    ) {
                        withAnimation(.easeInOut(duration: 0.22)) { dateOverridesExpanded.toggle() }
                    }
                } footer: {
                    if dateOverridesExpanded {
                        Text("Tap a date to start blocking. Tap a blocked date to remove it. Overrides take priority over your weekly schedule.")
                            .font(.caption)
                    }
                }

                // MARK: Calendar Sync Section
                Section {
                    if calSyncExpanded {
                        calSyncToggleRow(icon: "g.circle.fill",        label: "Google Calendar",   iconColor: Color(red: 0.26, green: 0.52, blue: 0.96), key: "google")
                        calSyncToggleRow(icon: "envelope.circle.fill", label: "Microsoft Outlook", iconColor: Color(red: 0.0, green: 0.47, blue: 0.83),   key: "outlook")
                        calSyncToggleRow(icon: "calendar.circle.fill", label: "Apple Calendar",    iconColor: .red,                                        key: "apple")
                    }
                } header: {
                    sectionHeader(
                        "Calendar Sync",
                        badge: connectedCalCount > 0
                            ? "\(connectedCalCount) connected"
                            : nil,
                        badgeColor: .varefyProCyan,
                        isExpanded: calSyncExpanded
                    ) {
                        withAnimation(.easeInOut(duration: 0.22)) { calSyncExpanded.toggle() }
                    }
                } footer: {
                    if calSyncExpanded {
                        Text("Sync your schedule and blocked dates with your personal calendar to prevent double-booking.")
                            .font(.caption)
                    }
                }

                // MARK: Job Filters Section
                Section {
                    if jobFiltersExpanded {
                        // Service Radius
                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundStyle(Color.varefyProCyan)
                                    .frame(width: 22)
                                Text("Service Radius")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(serviceRadius)) mi")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.varefyProCyan)
                                    .monospacedDigit()
                                    .frame(width: 48, alignment: .trailing)
                            }
                            Slider(value: $serviceRadius, in: 5...150, step: 5)
                                .tint(Color.varefyProCyan)
                                .padding(.leading, 28)
                        }
                        .padding(.vertical, 4)

                        // Max Job Distance
                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: "arrow.left.and.right.circle.fill")
                                    .foregroundStyle(.purple)
                                    .frame(width: 22)
                                Text("Max Job Distance")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(maxDistance)) mi")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.purple)
                                    .monospacedDigit()
                                    .frame(width: 48, alignment: .trailing)
                            }
                            Slider(value: $maxDistance, in: 5...150, step: 5)
                                .tint(.purple)
                                .padding(.leading, 28)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    sectionHeader(
                        "Job Filters",
                        badge: "\(Int(serviceRadius)) mi · \(Int(maxDistance)) mi max",
                        badgeColor: .varefyProCyan,
                        isExpanded: jobFiltersExpanded
                    ) {
                        withAnimation(.easeInOut(duration: 0.22)) { jobFiltersExpanded.toggle() }
                    }
                } footer: {
                    if jobFiltersExpanded {
                        Text("Drag to set how far you're willing to travel for jobs and the radius you serve.")
                            .font(.caption)
                    }
                }

                // MARK: Preferences Section
                Section {
                    if prefsExpanded {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.varefyProGold)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Min Client Rating")
                                    .font(.subheadline)
                                Text(minRating == 0 ? "No minimum" : "\(minRating) star\(minRating == 1 ? "" : "s") & up")
                                    .font(.caption)
                                    .foregroundStyle(minRating == 0 ? Color.secondary : Color.varefyProGold)
                            }
                            Spacer()
                            // Star picker
                            HStack(spacing: 6) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= minRating ? "star.fill" : "star")
                                        .font(.title3)
                                        .foregroundStyle(star <= minRating ? Color.varefyProGold : Color.secondary.opacity(0.4))
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                minRating = (minRating == star) ? 0 : star
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    sectionHeader(
                        "Preferences",
                        badge: minRating > 0 ? "\(minRating)★ min" : nil,
                        badgeColor: .varefyProGold,
                        isExpanded: prefsExpanded
                    ) {
                        withAnimation(.easeInOut(duration: 0.22)) { prefsExpanded.toggle() }
                    }
                } footer: {
                    if prefsExpanded {
                        Text("Only show jobs from clients who meet your minimum rating. Tap a star to set, tap again to clear.")
                            .font(.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Field Controls")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .closeButton()
    }

    // MARK: Section Header Helper

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
                if let badge = badge {
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

    // MARK: Day Row

    @ViewBuilder
    private func dayRow(index: Int) -> some View {
        let day = schedule[index]

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Toggle("", isOn: $schedule[index].isOn)
                    .labelsHidden()
                    .tint(Color.varefyProCyan)
                    .onChange(of: schedule[index].isOn) { _, isOn in
                        if !isOn {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                schedule[index].isExpanded = false
                            }
                        }
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(day.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(day.isOn ? .primary : .secondary)
                    Text(day.abbrev)
                        .font(.caption2)
                        .foregroundStyle(day.isOn ? .secondary : .tertiary)
                }

                Spacer()

                if day.isOn {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            schedule[index].isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(day.timeLabel)
                                .font(.caption)
                                .foregroundStyle(Color.varefyProCyan)
                            Image(systemName: day.isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Color.varefyProCyan)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.varefyProCyan.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.highlightRow)
                } else {
                    Text("Off")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.secondary.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if day.isOn && day.isExpanded {
                Divider().padding(.leading, 16)

                HStack {
                    Image(systemName: "sunrise.fill")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProGold)
                        .frame(width: 18)
                    Text("Start")
                        .font(.subheadline)
                    Spacer()
                    DatePicker("", selection: $schedule[index].startTime,
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.varefyProCyan)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 16)

                HStack {
                    Image(systemName: "sunset.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .frame(width: 18)
                    Text("End")
                        .font(.subheadline)
                    Spacer()
                    DatePicker("", selection: $schedule[index].endTime,
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.varefyProCyan)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().padding(.leading, 16)

                Button {
                    applyHoursToAll(from: index)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        schedule[index].isExpanded = false
                    }
                } label: {
                    Label("Apply these hours to all active days",
                          systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.varefyProCyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.highlightRow)
            }
        }
    }

    // MARK: Calendar Day Cell

    @ViewBuilder
    private func dayCellView(_ date: Date) -> some View {
        let cal     = Calendar.current
        let blocked = isBlocked(date)
        let today   = cal.isDateInToday(date)
        let past    = date < cal.startOfDay(for: Date())
        let pending = rangeStart.map { cal.isDate($0, inSameDayAs: date) } ?? false

        let bg: Color = blocked ? .red.opacity(0.65)
                      : pending ? Color.varefyProCyan
                      : today   ? Color.varefyProCyan.opacity(0.22)
                      : .clear

        let fg: Color = blocked ? .white
                      : pending ? .black
                      : .primary

        ZStack {
            Circle().fill(bg).padding(2)
            Text("\(cal.component(.day, from: date))")
                .font(.caption2)
                .fontWeight(today || blocked || pending ? .bold : .regular)
                .foregroundStyle(fg)
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .opacity(past && !blocked ? 0.3 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.18)) { handleDayTap(date) }
        }
    }

    // MARK: Calendar Sync Toggle Row

    @ViewBuilder
    private func calSyncToggleRow(icon: String, label: String, iconColor: Color, key: String) -> some View {
        let isOn = connectedCalendar == key
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                if isOn {
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { connectedCalendar == key },
                set: { on in connectedCalendar = on ? key : nil }
            ))
            .labelsHidden()
            .tint(Color.varefyProCyan)
        }
    }

    // MARK: Quick-Set Button

    @ViewBuilder
    private func quickSetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.appCard)
                .clipShape(Capsule())
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: Calendar Helpers

    private func calendarWeeks() -> [[Date?]] {
        let cal   = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }

        let leadingBlanks = cal.component(.weekday, from: first) - 1
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            var c = comps; c.day = day
            days.append(cal.date(from: c))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0+7, days.count)]) }
    }

    private func isBlocked(_ date: Date) -> Bool {
        let cal = Calendar.current
        let d = cal.startOfDay(for: date)
        return blockedRanges.contains {
            d >= cal.startOfDay(for: $0.start) && d <= cal.startOfDay(for: $0.end)
        }
    }

    private func handleDayTap(_ date: Date) {
        let cal = Calendar.current
        if isBlocked(date) {
            let d = cal.startOfDay(for: date)
            blockedRanges.removeAll { d >= cal.startOfDay(for: $0.start) && d <= cal.startOfDay(for: $0.end) }
            rangeStart = nil
            return
        }
        if let start = rangeStart {
            blockedRanges.append(BlockedRange(start: min(start, date), end: max(start, date)))
            rangeStart = nil
        } else {
            rangeStart = date
        }
    }

    private func shiftMonth(_ delta: Int) {
        guard let m = Calendar.current.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        displayedMonth = m
        rangeStart = nil
    }

    // MARK: Weekly Schedule Helpers

    private func applyDays(_ indices: [Int]) {
        for i in schedule.indices {
            let on = indices.contains(schedule[i].dayIndex)
            if !on { schedule[i].isExpanded = false }
            schedule[i].isOn = on
        }
    }

    private func applyHoursToAll(from sourceIndex: Int) {
        let src = schedule[sourceIndex]
        for i in schedule.indices where schedule[i].isOn && i != sourceIndex {
            schedule[i].startTime = src.startTime
            schedule[i].endTime   = src.endTime
        }
    }
}
