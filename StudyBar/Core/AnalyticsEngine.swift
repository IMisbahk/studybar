import Foundation

struct DayStudyTotal: Identifiable, Hashable {
    let date: Date
    let totalSeconds: TimeInterval
    let level: Int

    var id: Date { date }
}

struct WeekStudyTotal: Identifiable, Hashable {
    let weekStart: Date
    let totalSeconds: TimeInterval

    var id: Date { weekStart }
}

struct SubjectStudyTotal: Identifiable, Hashable {
    let name: String
    let totalSeconds: TimeInterval

    var id: String { name }
}

enum AnalyticsEngine {
    private static var calendar: Calendar { .current }

    static func dailyTotals(from sessions: [StudySession], trailingDays: Int = 365) -> [DayStudyTotal] {
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(trailingDays - 1), to: today) else { return [] }

        let grouped = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.startedAt) }
        let maxDaily = grouped.values.map { total(for: $0) }.max() ?? 0

        var result: [DayStudyTotal] = []
        var day = start
        while day <= today {
            let daySessions = grouped[day] ?? []
            let total = total(for: daySessions)
            result.append(DayStudyTotal(date: day, totalSeconds: total, level: heatLevel(total: total, max: maxDaily)))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    static func weeklyTotals(from sessions: [StudySession], trailingWeeks: Int = 12) -> [WeekStudyTotal] {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        var result: [WeekStudyTotal] = []
        for offset in stride(from: trailingWeeks - 1, through: 0, by: -1) {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeek),
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
            let weekSessions = sessions.filter { $0.startedAt >= weekStart && $0.startedAt < weekEnd }
            result.append(WeekStudyTotal(weekStart: weekStart, totalSeconds: total(for: weekSessions)))
        }
        return result
    }

    static func subjectTotals(from sessions: [StudySession]) -> [SubjectStudyTotal] {
        Dictionary(grouping: sessions, by: \.subjectName)
            .map { SubjectStudyTotal(name: $0.key, totalSeconds: total(for: $0.value)) }
            .sorted { $0.totalSeconds > $1.totalSeconds }
    }

    static func currentStreak(from sessions: [StudySession]) -> Int {
        streakCount(from: sessions, endingAt: Date())
    }

    static func longestStreak(from sessions: [StudySession]) -> Int {
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        guard let earliest = activeDays.min(), let latest = activeDays.max() else { return 0 }
        var best = 0
        var current = 0
        var day = earliest
        while day <= latest {
            if activeDays.contains(day) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return best
    }

    static func sessionsWithNotes(from sessions: [StudySession]) -> [StudySession] {
        sessions.filter { session in
            guard let notes = session.notes else { return false }
            return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private static func streakCount(from sessions: [StudySession], endingAt date: Date) -> Int {
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        var count = 0
        var day = calendar.startOfDay(for: date)
        while activeDays.contains(day) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    private static func total(for sessions: [StudySession]) -> TimeInterval {
        sessions.reduce(0) { $0 + $1.actualDuration }
    }

    private static func heatLevel(total: TimeInterval, max: TimeInterval) -> Int {
        guard total > 0 else { return 0 }
        guard max > 0 else { return 1 }
        let ratio = total / max
        if ratio < 0.25 { return 1 }
        if ratio < 0.5 { return 2 }
        if ratio < 0.75 { return 3 }
        return 4
    }
}
