import Foundation

enum InsightCategory: String, CaseIterable, Hashable {
    case pattern
    case suggestion
    case warning
    case summary

    var title: String {
        switch self {
        case .pattern: "Patterns"
        case .suggestion: "Suggestions"
        case .warning: "Watch"
        case .summary: "Summary"
        }
    }
}

struct StudyInsight: Identifiable, Hashable {
    let id: String
    let category: InsightCategory
    let title: String
    let message: String
    let detail: String?
    let systemImage: String
}

struct InsightsSnapshot: Hashable {
    let insights: [StudyInsight]
    let weeklySummary: String
    let monthlySummary: String
    let suggestedSessionMinutes: Int?
    let hasEnoughData: Bool

    static func build(from sessions: [StudySession]) -> InsightsSnapshot {
        let hasEnoughData = sessions.count >= 3
        return InsightsSnapshot(
            insights: InsightsEngine.insights(from: sessions),
            weeklySummary: InsightsEngine.weeklySummary(from: sessions),
            monthlySummary: InsightsEngine.monthlySummary(from: sessions),
            suggestedSessionMinutes: InsightsEngine.suggestedSessionMinutes(from: sessions),
            hasEnoughData: hasEnoughData
        )
    }
}

enum InsightsEngine {
    private static var calendar: Calendar { .current }

    static func insights(from sessions: [StudySession]) -> [StudyInsight] {
        guard sessions.count >= 3 else { return [] }
        var result: [StudyInsight] = []
        result.append(contentsOf: focusWindowInsights(from: sessions))
        result.append(contentsOf: weekdayInsights(from: sessions))
        result.append(contentsOf: subjectInsights(from: sessions))
        result.append(contentsOf: consistencyInsights(from: sessions))
        result.append(contentsOf: sessionLengthInsights(from: sessions))
        result.append(contentsOf: burnoutInsights(from: sessions))
        result.append(contentsOf: breakInsights(from: sessions))
        return result
    }

    static func weeklySummary(from sessions: [StudySession]) -> String {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return "Start a few sessions to unlock your weekly summary."
        }
        let weekSessions = sessions.filter { week.contains($0.startedAt) }
        guard !weekSessions.isEmpty else {
            return "No sessions yet this week — your summary will appear once you study."
        }
        let total = weekSessions.reduce(0) { $0 + $1.actualDuration }
        let completed = weekSessions.filter(\.completed).count
        let topSubject = Dictionary(grouping: weekSessions, by: \.subjectName)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.actualDuration }) }
            .max(by: { $0.1 < $1.1 })?.0 ?? "—"
        let bestDay = bestWeekdayLabel(in: weekSessions)
        let streak = AnalyticsEngine.currentStreak(from: sessions)
        return """
        This week: \(StudyFormatting.duration(total)) across \(weekSessions.count) session\(weekSessions.count == 1 ? "" : "s") (\(completed) completed).
        Top subject: \(topSubject). Strongest day: \(bestDay). Current streak: \(streak) day\(streak == 1 ? "" : "s").
        """
    }

    static func monthlySummary(from sessions: [StudySession]) -> String {
        guard let month = calendar.dateInterval(of: .month, for: Date()) else {
            return "Your monthly recap will show up after you log some study time."
        }
        let monthSessions = sessions.filter { month.contains($0.startedAt) }
        guard !monthSessions.isEmpty else {
            return "No sessions this month yet."
        }
        let total = monthSessions.reduce(0) { $0 + $1.actualDuration }
        let avg = total / Double(monthSessions.count)
        let focus = AnalyticsEngine.overview(from: sessions).focusScore
        let consistency = AnalyticsEngine.overview(from: sessions).consistencyScore
        let monthChange = AnalyticsEngine.monthComparison(from: sessions).changePercent
        var lines = [
            "\(month.start.formatted(.dateTime.month(.wide))): \(StudyFormatting.duration(total)) in \(monthSessions.count) sessions.",
            "Average session: \(StudyFormatting.duration(avg)). Focus \(focus)/100 · Consistency \(consistency)/100."
        ]
        if let monthChange {
            let sign = monthChange >= 0 ? "+" : ""
            lines.append("Vs last month: \(sign)\(Int(monthChange.rounded()))% study time.")
        }
        return lines.joined(separator: " ")
    }

    static func suggestedSessionMinutes(from sessions: [StudySession]) -> Int? {
        guard sessions.count >= 5 else { return nil }
        let durations = sessions.map(\.actualDuration).filter { $0 >= 60 }.sorted()
        guard !durations.isEmpty else { return nil }
        let medianMinutes = durations[durations.count / 2] / 60
        let presets: [Int] = [25, 45, 50, 90]
        return presets.min(by: { abs(Double($0) - medianMinutes) < abs(Double($1) - medianMinutes) })
    }

    // MARK: - generators

    private static func focusWindowInsights(from sessions: [StudySession]) -> [StudyInsight] {
        var bestStart = 0
        var bestScore: Double = 0
        for start in 0..<22 {
            let window = (start..<(start + 3))
            let inWindow = sessions.filter {
                let hour = calendar.component(.hour, from: $0.startedAt)
                return window.contains(hour)
            }
            guard inWindow.count >= 2 else { continue }
            let total = inWindow.reduce(0) { $0 + $1.actualDuration }
            let completion = Double(inWindow.filter(\.completed).count) / Double(inWindow.count)
            let score = total * (0.6 + completion * 0.4)
            if score > bestScore {
                bestScore = score
                bestStart = start
            }
        }
        guard bestScore > 0 else { return [] }
        let endHour = (bestStart + 3) % 24
        return [StudyInsight(
            id: "focus-window",
            category: .pattern,
            title: "Peak focus window",
            message: "You focus best between \(formatHour(bestStart)) and \(formatHour(endHour)).",
            detail: "Based on session length and completion rate in that window.",
            systemImage: "moon.stars.fill"
        )]
    }

    private static func weekdayInsights(from sessions: [StudySession]) -> [StudyInsight] {
        let weekday = AnalyticsEngine.overview(from: sessions).mostProductiveWeekday
        guard weekday != "—" else { return [] }
        return [StudyInsight(
            id: "strong-weekday",
            category: .pattern,
            title: "Strongest day",
            message: "\(weekday)s are your strongest study day.",
            detail: "Most total study time lands on this weekday.",
            systemImage: "calendar.circle.fill"
        )]
    }

    private static func subjectInsights(from sessions: [StudySession]) -> [StudyInsight] {
        let grouped = Dictionary(grouping: sessions, by: \.subjectName)
        let avgs = grouped.mapValues { list in
            list.reduce(0) { $0 + $1.actualDuration } / Double(list.count)
        }
        let overallAvg = avgs.values.reduce(0, +) / Double(max(1, avgs.count))
        guard overallAvg > 0,
              let top = avgs.max(by: { $0.value < $1.value }),
              top.value > overallAvg * 1.15,
              grouped[top.key]?.count ?? 0 >= 3 else { return [] }
        let pct = Int(((top.value - overallAvg) / overallAvg * 100).rounded())
        return [StudyInsight(
            id: "subject-\(top.key)",
            category: .pattern,
            title: top.key,
            message: "You study \(top.key) \(pct)% longer than your average session.",
            detail: "Avg \(StudyFormatting.duration(top.value)) vs \(StudyFormatting.duration(overallAvg)) overall.",
            systemImage: "books.vertical.fill"
        )]
    }

    private static func consistencyInsights(from sessions: [StudySession]) -> [StudyInsight] {
        let today = calendar.startOfDay(for: Date())
        guard let recentStart = calendar.date(byAdding: .day, value: -13, to: today),
              let priorStart = calendar.date(byAdding: .day, value: -27, to: today),
              let priorEnd = calendar.date(byAdding: .day, value: -14, to: today) else { return [] }
        let recentDays = activeDayCount(sessions, from: recentStart, to: today)
        let priorDays = activeDayCount(sessions, from: priorStart, to: priorEnd)
        guard priorDays > 0 else { return [] }
        let change = Double(recentDays - priorDays) / Double(priorDays) * 100
        guard abs(change) >= 10 else { return [] }
        if change > 0 {
            return [StudyInsight(
                id: "consistency-up",
                category: .pattern,
                title: "Consistency improving",
                message: "You've improved your consistency by \(Int(change.rounded()))% over the last two weeks.",
                detail: "\(recentDays) active days recently vs \(priorDays) in the prior period.",
                systemImage: "chart.line.uptrend.xyaxis"
            )]
        }
        return [StudyInsight(
            id: "consistency-down",
            category: .suggestion,
            title: "Consistency dip",
            message: "Active study days dropped \(Int(abs(change).rounded()))% vs the prior two weeks.",
            detail: "Short daily sessions beat occasional marathons.",
            systemImage: "arrow.down.right.circle"
        )]
    }

    private static func sessionLengthInsights(from sessions: [StudySession]) -> [StudyInsight] {
        guard let suggested = suggestedSessionMinutes(from: sessions) else { return [] }
        let durations = sessions.map(\.actualDuration).sorted()
        let median = durations[durations.count / 2]
        let typical = Int((median / 60).rounded())
        var result: [StudyInsight] = [StudyInsight(
            id: "typical-length",
            category: .pattern,
            title: "Typical session",
            message: "You typically stop after about \(typical) minutes.",
            detail: nil,
            systemImage: "timer"
        )]
        if abs(typical - suggested) >= 5 {
            result.append(StudyInsight(
                id: "suggest-length",
                category: .suggestion,
                title: "Try \(suggested) minutes",
                message: "Would you prefer \(suggested)-minute sessions? That matches your median length.",
                detail: "Rounded to a common preset from your history.",
                systemImage: "lightbulb.fill"
            ))
        }
        return result
    }

    private static func burnoutInsights(from sessions: [StudySession]) -> [StudyInsight] {
        var warnings: [StudyInsight] = []
        let todayTotal = sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.actualDuration }
        if todayTotal >= 6 * 3600 {
            warnings.append(StudyInsight(
                id: "long-day",
                category: .warning,
                title: "Long study day",
                message: "You've studied \(StudyFormatting.duration(todayTotal)) today — unusually high.",
                detail: "Consider wrapping up and resting.",
                systemImage: "exclamationmark.triangle.fill"
            ))
        }
        let lateSessions = sessions.filter {
            calendar.isDateInToday($0.startedAt) && calendar.component(.hour, from: $0.startedAt) >= 23
        }
        if !lateSessions.isEmpty {
            let lateTotal = lateSessions.reduce(0) { $0 + $1.actualDuration }
            warnings.append(StudyInsight(
                id: "late-night",
                category: .warning,
                title: "Late-night studying",
                message: "\(StudyFormatting.duration(lateTotal)) logged after 11 PM today.",
                detail: "Late sessions often correlate with lower next-day focus.",
                systemImage: "moon.zzz.fill"
            ))
        }
        let today = calendar.startOfDay(for: Date())
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) {
            let recent = sessions.filter { $0.startedAt >= threeDaysAgo }
            let dayTotals = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.startedAt) }
                .mapValues { $0.reduce(0) { $0 + $1.actualDuration } }
            let avgDaily = dayTotals.values.reduce(0, +) / Double(max(1, dayTotals.count))
            if avgDaily >= 4 * 3600, dayTotals.count >= 3 {
                warnings.append(StudyInsight(
                    id: "burnout-pace",
                    category: .warning,
                    title: "Heavy stretch",
                    message: "You're averaging \(StudyFormatting.duration(avgDaily)) per day over the last 3 days.",
                    detail: "Sustained high volume — schedule a lighter day.",
                    systemImage: "flame.fill"
                ))
            }
        }
        return warnings
    }

    private static func breakInsights(from sessions: [StudySession]) -> [StudyInsight] {
        let recent = sessions.prefix(10)
        var pauseHeavy = 0
        for session in recent {
            let pauseTime = session.segments
                .filter { $0.kind != .active }
                .reduce(0) { $0 + $1.endedAt.timeIntervalSince($1.startedAt) }
            if session.actualDuration > 0, pauseTime / session.actualDuration > 0.25 {
                pauseHeavy += 1
            }
        }
        if pauseHeavy >= 3 {
            return [StudyInsight(
                id: "break-suggest",
                category: .suggestion,
                title: "Pause pattern",
                message: "Recent sessions have a lot of pauses — shorter blocks with breaks might help.",
                detail: "\(pauseHeavy) of your last 10 sessions were pause-heavy.",
                systemImage: "cup.and.saucer.fill"
            )]
        }
        let longNoPause = sessions.prefix(5).contains { session in
            session.actualDuration >= 75 * 60 &&
            session.segments.filter { $0.kind != .active }.isEmpty
        }
        if longNoPause {
            return [StudyInsight(
                id: "break-long",
                category: .suggestion,
                title: "Take a break",
                message: "You've had long uninterrupted sessions lately — a 5-minute break can reset focus.",
                detail: nil,
                systemImage: "figure.walk"
            )]
        }
        return []
    }

    // MARK: - helpers

    private static func activeDayCount(_ sessions: [StudySession], from start: Date, to end: Date) -> Int {
        Set(
            sessions
                .filter { $0.startedAt >= start && $0.startedAt <= end }
                .map { calendar.startOfDay(for: $0.startedAt) }
        ).count
    }

    private static func bestWeekdayLabel(in sessions: [StudySession]) -> String {
        var totals: [Int: TimeInterval] = [:]
        for session in sessions {
            let wd = calendar.component(.weekday, from: session.startedAt)
            totals[wd, default: 0] += session.actualDuration
        }
        guard let best = totals.max(by: { $0.value < $1.value })?.key else { return "—" }
        return calendar.weekdaySymbols[best - 1]
    }

    private static func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h < 12 { return "\(h) AM" }
        if h == 12 { return "12 PM" }
        return "\(h - 12) PM"
    }
}
