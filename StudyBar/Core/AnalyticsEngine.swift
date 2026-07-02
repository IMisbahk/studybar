import Foundation

enum HeatmapRange: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case ytd
    case annual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .ytd: "YTD"
        case .annual: "Annual"
        }
    }

    var subtitle: String {
        switch self {
        case .weekly: "Last 7 days"
        case .monthly: "This month"
        case .ytd: "Year to date"
        case .annual: "Last 12 months"
        }
    }

    func interval(using calendar: Calendar = .current, now: Date = Date()) -> (start: Date, end: Date) {
        let end = calendar.startOfDay(for: now)
        let start: Date
        switch self {
        case .weekly:
            start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        case .monthly:
            start = calendar.date(from: calendar.dateComponents([.year, .month], from: end)) ?? end
        case .ytd:
            start = calendar.date(from: DateComponents(year: calendar.component(.year, from: end), month: 1, day: 1)) ?? end
        case .annual:
            start = calendar.date(byAdding: .day, value: -364, to: end) ?? end
        }
        return (calendar.startOfDay(for: start), end)
    }
}

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

    static func dailyTotals(from sessions: [StudySession], range: HeatmapRange = .annual) -> [DayStudyTotal] {
        let interval = range.interval()
        return dailyTotals(from: sessions, start: interval.start, end: interval.end)
    }

    static func dailyTotals(from sessions: [StudySession], trailingDays: Int = 365) -> [DayStudyTotal] {
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(trailingDays - 1), to: today) else { return [] }
        return dailyTotals(from: sessions, start: start, end: today)
    }

    private static func dailyTotals(from sessions: [StudySession], start: Date, end: Date) -> [DayStudyTotal] {
        let rangeStart = calendar.startOfDay(for: start)
        let rangeEnd = calendar.startOfDay(for: end)

        var byDay: [Date: TimeInterval] = [:]
        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            guard day >= rangeStart, day <= rangeEnd else { continue }
            byDay[day, default: 0] += session.actualDuration
        }

        let maxDaily = byDay.values.max() ?? 0
        var result: [DayStudyTotal] = []
        var day = rangeStart
        while day <= rangeEnd {
            let total = byDay[day] ?? 0
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
        let minutes = total / 60
        // absolute buckets so a single study day is always visible
        if minutes < 15 { return 1 }
        if minutes < 30 { return 2 }
        if minutes < 60 { return 3 }
        if max > 0, total >= max * 0.9 { return 4 }
        return 4
    }
}
