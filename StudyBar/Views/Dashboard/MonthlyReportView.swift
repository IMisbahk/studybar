import SwiftUI
import SwiftData

struct MonthlyReportView: View {
    let monthStart: Date
    let sessions: [StudySession]
    let achievementsUnlocked: [AchievementUnlock]

    private var calendar: Calendar { .current }

    private var monthSessions: [StudySession] {
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [] }
        return sessions.filter { $0.startedAt >= monthStart && $0.startedAt < monthEnd }
    }

    private var monthTitle: String {
        monthStart.formatted(.dateTime.month(.wide).year())
    }

    private var totalSeconds: TimeInterval {
        monthSessions.reduce(0) { $0 + $1.actualDuration }
    }

    private var averageSession: TimeInterval {
        guard !monthSessions.isEmpty else { return 0 }
        return totalSeconds / Double(monthSessions.count)
    }

    private var topSubject: String {
        Dictionary(grouping: monthSessions, by: \.subjectName)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.actualDuration }) }
            .max(by: { $0.1 < $1.1 })?.0 ?? "—"
    }

    private var longestDay: (date: Date, seconds: TimeInterval)? {
        let grouped = Dictionary(grouping: monthSessions) { calendar.startOfDay(for: $0.startedAt) }
        guard let best = grouped.max(by: { a, b in
            a.value.reduce(0) { $0 + $1.actualDuration } < b.value.reduce(0) { $0 + $1.actualDuration }
        }) else { return nil }
        return (best.key, best.value.reduce(0) { $0 + $1.actualDuration })
    }

    private var monthAchievements: [AchievementUnlock] {
        guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return [] }
        return achievementsUnlocked.filter { $0.unlockedAt >= monthStart && $0.unlockedAt < monthEnd }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("StudyBar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(monthTitle) Report")
                    .font(.largeTitle.bold())
            }

            Divider()

            reportRow("Total Hours", StudyFormatting.duration(totalSeconds))
            reportRow("Average Session", StudyFormatting.duration(averageSession))
            reportRow("Most Studied Subject", topSubject)
            if let longestDay {
                reportRow(
                    "Longest Day",
                    "\(longestDay.date.formatted(date: .abbreviated, time: .omitted)) · \(StudyFormatting.duration(longestDay.seconds))"
                )
            }
            reportRow("Current Streak", "\(AnalyticsEngine.currentStreak(from: sessions)) days")
            reportRow("Sessions", "\(monthSessions.count)")
            reportRow("Achievements Earned", "\(monthAchievements.count)")

            if !monthAchievements.isEmpty {
                Divider()
                Text("New Achievements")
                    .font(.headline)
                ForEach(monthAchievements.prefix(12), id: \.persistentModelID) { unlock in
                    Text("• \(achievementTitle(for: unlock))")
                        .font(.caption)
                }
            }

            Spacer(minLength: 0)
            Text("Generated \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(width: 520, alignment: .leading)
        .background(Color.white)
    }

    private func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func achievementTitle(for unlock: AchievementUnlock) -> String {
        if let global = AchievementCatalog.global.first(where: { $0.id == unlock.achievementId }) {
            return global.displayTitle(subjectName: unlock.subjectName)
        }
        if let subject = AchievementCatalog.subjectTemplates.first(where: { $0.id == unlock.achievementId }) {
            return subject.displayTitle(subjectName: unlock.subjectName)
        }
        return unlock.achievementId
    }
}
