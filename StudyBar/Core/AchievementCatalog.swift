import Foundation

enum AchievementCategory: String, CaseIterable, Identifiable {
    case sessions
    case time
    case streaks
    case habits
    case subjects
    case levels

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sessions: "Sessions"
        case .time: "Time"
        case .streaks: "Streaks"
        case .habits: "Habits"
        case .subjects: "Subjects"
        case .levels: "Levels"
        }
    }
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let category: AchievementCategory
    let subjectScoped: Bool
    let evaluate: (GamificationSnapshot, String?) -> Bool

    func displayTitle(subjectName: String?) -> String {
        guard subjectScoped, let subjectName else { return title }
        return title.replacingOccurrences(of: "{subject}", with: subjectName)
    }

    func displayDetail(subjectName: String?) -> String {
        guard subjectScoped, let subjectName else { return detail }
        return detail.replacingOccurrences(of: "{subject}", with: subjectName)
    }
}

struct GamificationSnapshot {
    let sessions: [StudySession]
    let profile: ProfileProgress
    let subjects: [SubjectProgress]
    let unlockedKeys: Set<String>
    let triggeringSession: StudySession?

    var totalSessions: Int { sessions.count }
    var totalHours: Double { sessions.reduce(0) { $0 + $1.actualDuration } / 3600 }
    var currentStreak: Int { AnalyticsEngine.currentStreak(from: sessions) }
    var longestStreak: Int { AnalyticsEngine.longestStreak(from: sessions) }
    var overallLevel: Int { GamificationEngine.level(forTotalXp: profile.totalXp) }

    func sessions(for subject: String) -> [StudySession] {
        sessions.filter { $0.subjectName == subject }
    }

    func hours(for subject: String) -> Double {
        sessions(for: subject).reduce(0) { $0 + $1.actualDuration } / 3600
    }

    func subjectNames() -> [String] {
        Array(Set(sessions.map(\.subjectName))).sorted()
    }

    func unlockKey(achievementId: String, subjectName: String?) -> String {
        if let subjectName { return "\(achievementId)|\(subjectName)" }
        return achievementId
    }

    func isUnlocked(achievementId: String, subjectName: String?) -> Bool {
        unlockedKeys.contains(unlockKey(achievementId: achievementId, subjectName: subjectName))
    }
}

enum AchievementCatalog {
    static let backfillVersion = 1

    static var all: [AchievementDefinition] {
        global + subjectTemplates
    }

    static var global: [AchievementDefinition] {
        sessionMilestones + hourMilestones + streakMilestones + levelMilestones + habitMilestones + weekdayMilestones
    }

    static var subjectTemplates: [AchievementDefinition] {
        [
            def("subject_first", "First Steps in {subject}", "Complete your first session in {subject}", "star.fill", .subjects, true) { snap, subject in
                guard let subject else { return false }
                return snap.sessions(for: subject).count >= 1
            },
            def("subject_sessions_10", "{subject} Regular", "10 sessions in {subject}", "10.circle.fill", .subjects, true) { snap, subject in
                guard let subject else { return false }
                return snap.sessions(for: subject).count >= 10
            },
            def("subject_sessions_50", "{subject} Devotee", "50 sessions in {subject}", "50.circle.fill", .subjects, true) { snap, subject in
                guard let subject else { return false }
                return snap.sessions(for: subject).count >= 50
            },
            def("subject_hours_5", "{subject} Apprentice", "5 hours in {subject}", "clock.fill", .subjects, true) { snap, subject in
                guard let subject else { return false }
                return snap.hours(for: subject) >= 5
            },
            def("subject_hours_25", "{subject} Adept", "25 hours in {subject}", "clock.badge.checkmark", .subjects, true) { snap, subject in
                guard let subject else { return false }
                return snap.hours(for: subject) >= 25
            },
            def("subject_hours_50", "{subject} Expert", "50 hours in {subject}", "graduationcap.fill", .subjects, true) { snap, subject in
                guard let subject else { return false }
                return snap.hours(for: subject) >= 50
            },
            def("subject_hours_100", "{subject} Master", "100 hours in {subject}", "crown.fill", .subjects, true) { snap, subject in
                guard let subject else { return false }
                return snap.hours(for: subject) >= 100
            },
            def("subject_level_10", "{subject} Level 10", "Reach level 10 in {subject}", "bolt.fill", .subjects, true) { snap, subject in
                guard let subject else { return false }
                let xp = snap.subjects.first { $0.subjectName == subject }?.totalXp ?? 0
                return GamificationEngine.level(forTotalXp: xp) >= 10
            },
        ]
    }

    private static let sessionCounts = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125, 150, 200, 250, 300, 400, 500, 750, 1000]
    private static let hourCounts = [1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 40, 50, 75, 100, 150, 200, 250, 300, 400, 500, 750, 1000]
    private static let streakCounts = [2, 3, 5, 7, 10, 14, 21, 30, 45, 60, 90, 100, 180, 365]
    private static let levelCounts = [5, 10, 15, 20, 25, 30, 40, 50]

    private static var sessionMilestones: [AchievementDefinition] {
        sessionCounts.map { count in
            let title: String
            switch count {
            case 1: title = "First Session"
            case 10: title = "Getting Started"
            case 100: title = "Century"
            case 500: title = "Dedicated Scholar"
            case 1000: title = "Session Legend"
            default: title = "\(count) Sessions"
            }
            return def("sessions_\(count)", title, "Complete \(count) study sessions", "checkmark.circle.fill", .sessions, false) { snap, _ in
                snap.totalSessions >= count
            }
        }
    }

    private static var hourMilestones: [AchievementDefinition] {
        hourCounts.map { hours in
            let title: String
            switch hours {
            case 1: title = "First Hour"
            case 10: title = "Ten Hour Club"
            case 100: title = "Hundred Hours"
            case 1000: title = "Thousand Hour Titan"
            default: title = "\(hours) Hours"
            }
            return def("hours_\(hours)", title, "Study for \(hours) total hours", "hourglass", .time, false) { snap, _ in
                snap.totalHours >= Double(hours)
            }
        }
    }

    private static var streakMilestones: [AchievementDefinition] {
        streakCounts.map { days in
            let title: String
            switch days {
            case 7: title = "Week Warrior"
            case 30: title = "Monthly Momentum"
            case 100: title = "Consistency King"
            case 365: title = "Year of Focus"
            default: title = "\(days) Day Streak"
            }
            return def("streak_\(days)", title, "Study \(days) days in a row", "flame.fill", .streaks, false) { snap, _ in
                snap.longestStreak >= days
            }
        }
    }

    private static var levelMilestones: [AchievementDefinition] {
        levelCounts.map { level in
            def("level_\(level)", "Level \(level)", "Reach overall level \(level)", "arrow.up.circle.fill", .levels, false) { snap, _ in
                snap.overallLevel >= level
            }
        }
    }

    private static var habitMilestones: [AchievementDefinition] {
        [
            def("night_owl", "Night Owl", "Finish a session after 10 PM", "moon.stars.fill", .habits, false) { snap, _ in
                snap.sessions.contains { Calendar.current.component(.hour, from: $0.endedAt) >= 22 }
            },
            def("early_bird", "Early Bird", "Start a session before 7 AM", "sunrise.fill", .habits, false) { snap, _ in
                snap.sessions.contains { Calendar.current.component(.hour, from: $0.startedAt) < 7 }
            },
            def("weekend_warrior", "Weekend Warrior", "Study on both Saturday and Sunday", "calendar", .habits, false) { snap, _ in
                let cal = Calendar.current
                let weekends = Set(snap.sessions.map { cal.component(.weekday, from: $0.startedAt) })
                return weekends.contains(1) && weekends.contains(7)
            },
            def("marathon", "Marathon", "Complete a 2+ hour session", "figure.run", .habits, false) { snap, _ in
                snap.sessions.contains { $0.actualDuration >= 2 * 3600 }
            },
            def("ultra_marathon", "Ultra Marathon", "Complete a 4+ hour session", "figure.run.circle", .habits, false) { snap, _ in
                snap.sessions.contains { $0.actualDuration >= 4 * 3600 }
            },
            def("perfect_week", "Perfect Week", "Study every day for 7 days", "7.circle.fill", .habits, false) { snap, _ in
                hasConsecutiveActiveDays(snap.sessions, count: 7)
            },
            def("perfect_month", "Perfect Month", "Study every day for 30 days", "30.circle.fill", .habits, false) { snap, _ in
                hasConsecutiveActiveDays(snap.sessions, count: 30)
            },
            def("no_break_week", "No Break Week", "7 days without a 2+ hour gap between study days", "bolt.horizontal.fill", .habits, false) { snap, _ in
                snap.longestStreak >= 7
            },
            def("finals_survivor", "Finals Survivor", "10+ hours in a single day", "shield.fill", .habits, false) { snap, _ in
                let cal = Calendar.current
                let byDay = Dictionary(grouping: snap.sessions) { cal.startOfDay(for: $0.startedAt) }
                return byDay.values.contains { $0.reduce(0) { $0 + $1.actualDuration } >= 10 * 3600 }
            },
            def("notes_keeper", "Notes Keeper", "Add notes to 10 sessions", "note.text", .habits, false) { snap, _ in
                snap.sessions.filter { ($0.notes?.isEmpty == false) }.count >= 10
            },
            def("stopwatch_pro", "Stopwatch Pro", "Complete 10 open-ended sessions", "stopwatch", .habits, false) { snap, _ in
                snap.sessions.filter(\.openEnded).count >= 10
            },
            def("triple_day", "Triple Shift", "3+ sessions in one day", "3.circle.fill", .habits, false) { snap, _ in
                let cal = Calendar.current
                let byDay = Dictionary(grouping: snap.sessions) { cal.startOfDay(for: $0.startedAt) }
                return byDay.values.contains { $0.count >= 3 }
            },
            def("scholar", "Scholar", "Study 5+ different subjects", "books.vertical.fill", .habits, false) { snap, _ in
                snap.subjectNames().count >= 5
            },
            def("iron_focus", "Iron Focus", "Complete a session with zero pauses", "scope", .habits, false) { snap, _ in
                snap.sessions.contains { session in
                    session.completed && session.segments.allSatisfy { $0.kind == .active }
                }
            },
            def("comeback", "Comeback", "Return after 7+ days off", "arrow.uturn.forward", .habits, false) { snap, _ in
                guard let trigger = snap.triggeringSession else { return false }
                let cal = Calendar.current
                let sorted = snap.sessions.sorted { $0.startedAt < $1.startedAt }
                guard sorted.count >= 2 else { return false }
                guard let idx = sorted.firstIndex(where: { $0.startedAt == trigger.startedAt }) else { return false }
                guard idx > 0 else { return false }
                let prev = sorted[idx - 1]
                let gap = cal.dateComponents([.day], from: cal.startOfDay(for: prev.startedAt), to: cal.startOfDay(for: trigger.startedAt)).day ?? 0
                return gap >= 7
            },
        ]
    }

    private static var weekdayMilestones: [AchievementDefinition] {
        let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return weekdays.enumerated().map { index, name in
            def("weekday_\(index + 1)", "\(name) Strength", "Study most on \(name)s", "calendar.circle", .habits, false) { snap, _ in
                strongestWeekday(snap.sessions) == index + 1
            }
        }
    }

    private static func def(
        _ id: String,
        _ title: String,
        _ detail: String,
        _ icon: String,
        _ category: AchievementCategory,
        _ subjectScoped: Bool,
        _ evaluate: @escaping (GamificationSnapshot, String?) -> Bool
    ) -> AchievementDefinition {
        AchievementDefinition(id: id, title: title, detail: detail, icon: icon, category: category, subjectScoped: subjectScoped, evaluate: evaluate)
    }

    private static func hasConsecutiveActiveDays(_ sessions: [StudySession], count: Int) -> Bool {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.startedAt) }).sorted()
        guard days.count >= count else { return false }
        var run = 1
        for i in 1..<days.count {
            let prev = days[i - 1]
            let expected = cal.date(byAdding: .day, value: 1, to: prev)!
            if cal.isDate(days[i], inSameDayAs: expected) {
                run += 1
                if run >= count { return true }
            } else {
                run = 1
            }
        }
        return false
    }

    private static func strongestWeekday(_ sessions: [StudySession]) -> Int {
        let cal = Calendar.current
        var totals: [Int: TimeInterval] = [:]
        for session in sessions {
            let wd = cal.component(.weekday, from: session.startedAt)
            totals[wd, default: 0] += session.actualDuration
        }
        return totals.max(by: { $0.value < $1.value })?.key ?? 1
    }
}
