import SwiftUI

// MARK: - Models

private struct MandatoryLesson: Identifiable {
    let id = UUID()
    let number: Int
    let title: String
    let tagline: String
    let duration: String
    let topics: [(icon: String, text: String)]
    let keyMessage: String
}

private struct LearningModule: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let duration: String
    let isCompleted: Bool
}

// MARK: - Main View

struct LearningView: View {
    @State private var selectedLesson: MandatoryLesson? = nil
    @State private var completedLessons: Set<UUID> = Set(LearningView.mandatoryLessons.map(\.id))

    private static let mandatoryLessons: [MandatoryLesson] = [
        .init(
            number: 1,
            title: "How to Guarantee You Get Paid",
            tagline: "The system mechanics that protect your payment",
            duration: "6 min",
            topics: [
                ("lock.fill",            "Payment is secured before the job starts"),
                ("arrow.triangle.turn.up.right.circle.fill", "Launch navigation using the Drive button"),
                ("mappin.circle.fill",   "GPS arrival verification"),
                ("camera.fill",          "Required pre-work photos"),
                ("play.circle.fill",     "Start Work — billing begins"),
                ("photo.on.rectangle",   "Required post-work photos"),
                ("checkmark.seal.fill",  "Completion → client review → payout"),
            ],
            keyMessage: "Follow the process and payment is guaranteed."
        ),
        .init(
            number: 2,
            title: "How to Increase Your Ranking and Repeat Rate",
            tagline: "Performance behaviors that lead to more jobs",
            duration: "5 min",
            topics: [
                ("bolt.fill",            "Respond quickly to requests"),
                ("checkmark.circle.fill","Accept jobs you can complete reliably"),
                ("clock.fill",           "Show up on time — GPS verified"),
                ("camera.fill",          "Take clear pre and post photos"),
                ("star.fill",            "Maintain strong ratings"),
                ("message.fill",         "Communicate with clients in chat"),
            ],
            keyMessage: "Better behavior = higher rank + more work."
        ),
    ]

    private let modules: [LearningModule] = [
        .init(icon: "checkmark.seal.fill",   title: "Getting Started on VareFy Pro",       subtitle: "Platform overview, work order flow, and your first job",   duration: "5 min", isCompleted: true),
        .init(icon: "camera.fill",            title: "Photo Documentation Standards",   subtitle: "What to capture before and after every job",              duration: "4 min", isCompleted: true),
        .init(icon: "clock.fill",             title: "Billing and Time Tracking",       subtitle: "How Start Work, pausing, and billing work",               duration: "3 min", isCompleted: true),
        .init(icon: "mappin.circle.fill",     title: "Job Radius and Location Rules",   subtitle: "Staying within bounds and handling large properties",      duration: "4 min", isCompleted: false),
        .init(icon: "star.fill",              title: "Earning and Maintaining Ratings", subtitle: "How ratings affect your visibility and job matching",      duration: "5 min", isCompleted: false),
        .init(icon: "shield.fill",            title: "Boss Plan Benefits",              subtitle: "Analytics, repeat clients, priority placement, and more", duration: "6 min", isCompleted: false),
        .init(icon: "dollarsign.circle.fill", title: "Getting Paid",                    subtitle: "Instant pay, bank transfers, fees, and payout timing",    duration: "4 min", isCompleted: false),
        .init(icon: "person.2.fill",          title: "H2H Collaboration",              subtitle: "How to partner with other Hires on larger jobs",           duration: "5 min", isCompleted: false),
    ]

    private var moduleCompletedCount: Int { modules.filter(\.isCompleted).count }
    private var mandatoryComplete: Bool { completedLessons.count >= LearningView.mandatoryLessons.count }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    mandatorySection
                    librarySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Learning")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .popButton()
        .sheet(item: $selectedLesson) { lesson in
            LessonDetailSheet(lesson: lesson, isCompleted: completedLessons.contains(lesson.id)) {
                completedLessons.insert(lesson.id)
            }
        }
    }

    // MARK: - Mandatory Section

    private var mandatorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.shield.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                Text("MANDATORY TRAINING")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundStyle(.orange)
                    .tracking(0.8)
                Spacer()
                if mandatoryComplete {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.varefyProCyan)
                            .font(.caption)
                        Text("Complete")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.varefyProCyan)
                    }
                } else {
                    Text("\(completedLessons.count)/\(LearningView.mandatoryLessons.count) done")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Complete both lessons before your first job. Available while your background check is processing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(LearningView.mandatoryLessons) { lesson in
                mandatoryCard(lesson)
            }
        }
    }

    @ViewBuilder
    private func mandatoryCard(_ lesson: MandatoryLesson) -> some View {
        let done = completedLessons.contains(lesson.id)
        Button {
            Haptics.light()
            selectedLesson = lesson
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(done ? Color.varefyProCyan.opacity(0.12) : Color.orange.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: done ? "checkmark.circle.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(done ? Color.varefyProCyan : .orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Lesson \(lesson.number)")
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundStyle(done ? Color.varefyProCyan : .orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((done ? Color.varefyProCyan : Color.orange).opacity(0.15))
                            .clipShape(Capsule())
                        Text(lesson.duration)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(lesson.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(lesson.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(14)
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(done ? Color.varefyProCyan.opacity(0.2) : Color.orange.opacity(0.25), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.highlightRow)
    }

    // MARK: - Library Section

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LIBRARY")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                Spacer()
                Text("\(moduleCompletedCount) of \(modules.count) done")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(modules) { module in
                    moduleRow(module)
                    if module.id != modules.last?.id {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func moduleRow(_ module: LearningModule) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(module.isCompleted ? Color.varefyProCyan.opacity(0.15) : Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                Image(systemName: module.isCompleted ? "checkmark" : module.icon)
                    .font(.subheadline)
                    .foregroundStyle(module.isCompleted ? Color.varefyProCyan : .secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(module.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(module.isCompleted ? .secondary : .primary)
                Text(module.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(module.duration)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .opacity(module.isCompleted ? 0.6 : 1)
    }
}

// MARK: - Lesson Detail Sheet

private struct LessonDetailSheet: View {
    let lesson: MandatoryLesson
    let isCompleted: Bool
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var marked = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Text("Lesson \(lesson.number)")
                                    .font(.caption)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(Capsule())
                                Text(lesson.duration)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(lesson.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(lesson.tagline)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        // Video placeholder
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.appCard)
                                .frame(height: 200)
                            VStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 52))
                                    .foregroundStyle(Color.varefyProCyan)
                                Text("Video coming soon")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Topics
                        VStack(alignment: .leading, spacing: 0) {
                            Text("WHAT YOU'LL LEARN")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 12)

                            ForEach(Array(lesson.topics.enumerated()), id: \.offset) { i, topic in
                                HStack(spacing: 12) {
                                    Image(systemName: topic.icon)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.varefyProCyan)
                                        .frame(width: 24)
                                    Text(topic.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                if i < lesson.topics.count - 1 {
                                    Divider().background(Color.white.opacity(0.06))
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.appCard)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Key message
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text(lesson.keyMessage)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(Color.orange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Mark complete button
                        if isCompleted || marked {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.varefyProCyan)
                                Text("Lesson Complete")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.varefyProCyan)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.varefyProCyan.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            Button {
                                Haptics.medium()
                                marked = true
                                onComplete()
                            } label: {
                                Text("Mark as Complete")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.varefyProCyan)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.varefyProCyan)
                }
            }
        }
    }
}
