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

struct DaySessionSummary: Identifiable, Hashable {
    let subjectName: String
    let topicName: String?
    let duration: TimeInterval
    let startedAt: Date

    var id: Date { startedAt }
}

struct DayStudyDetail: Hashable {
    let date: Date
    let totalSeconds: TimeInterval
    let sessions: [DaySessionSummary]
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

struct MonthStudyTotal: Identifiable, Hashable {
    let monthStart: Date
    let totalSeconds: TimeInterval

    var id: Date { monthStart }
}

struct HourStudyTotal: Identifiable, Hashable {
    let hour: Int
    let totalSeconds: TimeInterval

    var id: Int { hour }
}

struct AnalyticsOverview: Hashable {
    let totalStudySeconds: TimeInterval
    let totalSessions: Int
    let averageSessionLength: TimeInterval
    let longestSessionSeconds: TimeInterval
    let shortestSessionSeconds: TimeInterval
    let mostProductiveWeekday: String
    let mostProductiveHour: Int
    let averageDailyStudy: TimeInterval
    let longestUninterruptedSessionSeconds: TimeInterval
    let consistencyScore: Int
    let focusScore: Int
    let rolling7DayAverage: TimeInterval
    let rolling30DayAverage: TimeInterval
    let previousWeekChangePercent: Double?
    let previousMonthChangePercent: Double?
    let yearToDateSeconds: TimeInterval
}

struct PeriodComparison: Hashable {
    let currentSeconds: TimeInterval
    let previousSeconds: TimeInterval

    var changePercent: Double? {
        guard previousSeconds > 0 else { return currentSeconds > 0 ? 100 : nil }
        return ((currentSeconds - previousSeconds) / previousSeconds) * 100
    }
}

struct AnalyticsSnapshot {
    let overview: AnalyticsOverview
    let dailyTotals: [DayStudyTotal]
    let heatmapDayDetails: [Date: DayStudyDetail]
    let weeklyTotals: [WeekStudyTotal]
    let monthlyTotals: [MonthStudyTotal]
    let dailyTrailing30: [DayStudyTotal]
    let hourTotals: [HourStudyTotal]
    let subjectTotals: [SubjectStudyTotal]
    let currentStreak: Int
    let longestStreak: Int

    static func build(from sessions: [StudySession], heatmapRange: HeatmapRange) -> AnalyticsSnapshot {
        AnalyticsSnapshot(
            overview: AnalyticsEngine.overview(from: sessions),
            dailyTotals: AnalyticsEngine.dailyTotals(from: sessions, range: heatmapRange),
            heatmapDayDetails: AnalyticsEngine.dayDetails(from: sessions, range: heatmapRange),
            weeklyTotals: AnalyticsEngine.weeklyTotals(from: sessions, trailingWeeks: 12),
            monthlyTotals: AnalyticsEngine.monthlyTotals(from: sessions, trailingMonths: 12),
            dailyTrailing30: AnalyticsEngine.dailyTotalsTrailing(days: 30, from: sessions),
            hourTotals: AnalyticsEngine.hourOfDayTotals(from: sessions),
            subjectTotals: AnalyticsEngine.subjectTotals(from: sessions),
            currentStreak: AnalyticsEngine.currentStreak(from: sessions),
            longestStreak: AnalyticsEngine.longestStreak(from: sessions)
        )
    }
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

    static func dayDetails(from sessions: [StudySession], range: HeatmapRange = .annual) -> [Date: DayStudyDetail] {
        let interval = range.interval()
        let rangeStart = calendar.startOfDay(for: interval.start)
        let rangeEnd = calendar.startOfDay(for: interval.end)
        var grouped: [Date: [StudySession]] = [:]

        for session in sessions {
            let day = calendar.startOfDay(for: session.startedAt)
            guard day >= rangeStart, day <= rangeEnd else { continue }
            grouped[day, default: []].append(session)
        }

        var result: [Date: DayStudyDetail] = [:]
        for (day, daySessions) in grouped {
            let summaries = daySessions
                .sorted { $0.startedAt < $1.startedAt }
                .map {
                    DaySessionSummary(
                        subjectName: $0.subjectName,
                        topicName: $0.topicName,
                        duration: $0.actualDuration,
                        startedAt: $0.startedAt
                    )
                }
            result[day] = DayStudyDetail(
                date: day,
                totalSeconds: total(for: daySessions),
                sessions: summaries
            )
        }
        return result
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

    static func overview(from sessions: [StudySession]) -> AnalyticsOverview {
        let totalSeconds = total(for: sessions)
        let count = sessions.count
        let durations = sessions.map(\.actualDuration).filter { $0 > 0 }
        let avg = count > 0 ? totalSeconds / Double(count) : 0
        let longest = durations.max() ?? 0
        let shortest = durations.min() ?? 0
        let weekday = mostProductiveWeekday(from: sessions)
        let hour = mostProductiveHour(from: sessions)
        let avgDaily = averageDailyStudy(from: sessions)
        let longestSession = durations.max() ?? 0

        return AnalyticsOverview(
            totalStudySeconds: totalSeconds,
            totalSessions: count,
            averageSessionLength: avg,
            longestSessionSeconds: longest,
            shortestSessionSeconds: shortest,
            mostProductiveWeekday: weekday,
            mostProductiveHour: hour,
            averageDailyStudy: avgDaily,
            longestUninterruptedSessionSeconds: longestSession,
            consistencyScore: consistencyScore(from: sessions),
            focusScore: focusScore(from: sessions),
            rolling7DayAverage: rollingAverage(from: sessions, days: 7),
            rolling30DayAverage: rollingAverage(from: sessions, days: 30),
            previousWeekChangePercent: weekComparison(from: sessions).changePercent,
            previousMonthChangePercent: monthComparison(from: sessions).changePercent,
            yearToDateSeconds: yearToDateTotal(from: sessions)
        )
    }

    static func monthlyTotals(from sessions: [StudySession], trailingMonths: Int = 12) -> [MonthStudyTotal] {
        guard let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else { return [] }
        var result: [MonthStudyTotal] = []
        for offset in stride(from: trailingMonths - 1, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: thisMonth),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let monthSessions = sessions.filter { $0.startedAt >= monthStart && $0.startedAt < monthEnd }
            result.append(MonthStudyTotal(monthStart: monthStart, totalSeconds: total(for: monthSessions)))
        }
        return result
    }

    static func hourOfDayTotals(from sessions: [StudySession]) -> [HourStudyTotal] {
        var buckets = Array(repeating: TimeInterval(0), count: 24)
        for session in sessions {
            let hour = calendar.component(.hour, from: session.startedAt)
            buckets[hour] += session.actualDuration
        }
        return buckets.enumerated().map { HourStudyTotal(hour: $0.offset, totalSeconds: $0.element) }
    }

    static func dailyTotalsTrailing(days: Int, from sessions: [StudySession]) -> [DayStudyTotal] {
        dailyTotals(from: sessions, trailingDays: days)
    }

    static func weekComparison(from sessions: [StudySession]) -> PeriodComparison {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date()),
              let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek.start),
              let lastWeekEnd = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek.end) else {
            return PeriodComparison(currentSeconds: 0, previousSeconds: 0)
        }
        let current = total(for: sessions.filter { thisWeek.contains($0.startedAt) })
        let previous = total(for: sessions.filter { $0.startedAt >= lastWeekStart && $0.startedAt < lastWeekEnd })
        return PeriodComparison(currentSeconds: current, previousSeconds: previous)
    }

    static func monthComparison(from sessions: [StudySession]) -> PeriodComparison {
        let now = Date()
        guard let thisMonth = calendar.dateInterval(of: .month, for: now),
              let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonth.start),
              let lastMonthEnd = calendar.date(byAdding: .month, value: -1, to: thisMonth.end) else {
            return PeriodComparison(currentSeconds: 0, previousSeconds: 0)
        }
        let current = total(for: sessions.filter { thisMonth.contains($0.startedAt) })
        let previous = total(for: sessions.filter { $0.startedAt >= lastMonthStart && $0.startedAt < lastMonthEnd })
        return PeriodComparison(currentSeconds: current, previousSeconds: previous)
    }

    static func subjectTrends(from sessions: [StudySession], trailingWeeks: Int = 8) -> [String: [WeekStudyTotal]] {
        let names = Set(sessions.map(\.subjectName))
        var result: [String: [WeekStudyTotal]] = [:]
        for name in names {
            let subjectSessions = sessions.filter { $0.subjectName == name }
            result[name] = weeklyTotals(from: subjectSessions, trailingWeeks: trailingWeeks)
        }
        return result
    }

    private static func yearToDateTotal(from sessions: [StudySession]) -> TimeInterval {
        let interval = HeatmapRange.ytd.interval()
        return total(for: sessions.filter { $0.startedAt >= interval.start })
    }

    private static func rollingAverage(from sessions: [StudySession], days: Int) -> TimeInterval {
        let today = calendar.startOfDay(for: Date())
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) else { return 0 }
        let windowSessions = sessions.filter { $0.startedAt >= start }
        guard !windowSessions.isEmpty else { return 0 }
        return total(for: windowSessions) / Double(days)
    }

    private static func averageDailyStudy(from sessions: [StudySession]) -> TimeInterval {
        guard let first = sessions.map(\.startedAt).min() else { return 0 }
        let start = calendar.startOfDay(for: first)
        let end = calendar.startOfDay(for: Date())
        let dayCount = max(1, (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
        return total(for: sessions) / Double(dayCount)
    }

    private static func mostProductiveWeekday(from sessions: [StudySession]) -> String {
        var totals: [Int: TimeInterval] = [:]
        for session in sessions {
            let wd = calendar.component(.weekday, from: session.startedAt)
            totals[wd, default: 0] += session.actualDuration
        }
        guard let best = totals.max(by: { $0.value < $1.value })?.key else { return "—" }
        return calendar.weekdaySymbols[best - 1]
    }

    private static func mostProductiveHour(from sessions: [StudySession]) -> Int {
        var totals = Array(repeating: TimeInterval(0), count: 24)
        for session in sessions {
            let hour = calendar.component(.hour, from: session.startedAt)
            totals[hour] += session.actualDuration
        }
        return totals.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
    }

    // active study days / span — simple consistency metric
    private static func consistencyScore(from sessions: [StudySession]) -> Int {
        guard let first = sessions.map(\.startedAt).min() else { return 0 }
        let start = calendar.startOfDay(for: first)
        let end = calendar.startOfDay(for: Date())
        let span = max(1, (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
        let activeDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) }).count
        let streakBoost = min(20, longestStreak(from: sessions) * 2)
        let base = Int((Double(activeDays) / Double(span)) * 80)
        return min(100, base + streakBoost)
    }

    // completion + low pause time = focus
    private static func focusScore(from sessions: [StudySession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let completedRatio = Double(sessions.filter(\.completed).count) / Double(sessions.count)
        var pauseSeconds: TimeInterval = 0
        var activeSeconds: TimeInterval = 0
        for session in sessions {
            for segment in session.segments {
                let duration = segment.endedAt.timeIntervalSince(segment.startedAt)
                if segment.kind == .active {
                    activeSeconds += duration
                } else {
                    pauseSeconds += duration
                }
            }
            if session.segments.isEmpty {
                activeSeconds += session.actualDuration
            }
        }
        let pauseRatio = activeSeconds > 0 ? pauseSeconds / (activeSeconds + pauseSeconds) : 0
        let raw = completedRatio * 70 + (1 - min(1, pauseRatio)) * 30
        return min(100, max(0, Int(raw.rounded())))
    }
}
