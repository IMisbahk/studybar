import Foundation
import SwiftData

struct StudyGoalProgress: Hashable {
    let currentSeconds: TimeInterval
    let goalSeconds: TimeInterval
    let label: String

    var fraction: Double {
        guard goalSeconds > 0 else { return 0 }
        return min(1, currentSeconds / goalSeconds)
    }

    var isComplete: Bool { currentSeconds >= goalSeconds && goalSeconds > 0 }
}

enum StudyGoalHelper {
    private static var calendar: Calendar { .current }

    static var dailyGoalMinutes: Int {
        UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
    }

    static var weeklyGoalMinutes: Int {
        UserDefaults.standard.integer(forKey: "weeklyGoalMinutes")
    }

    static func dailyProgress(from sessions: [StudySession]) -> StudyGoalProgress? {
        let minutes = dailyGoalMinutes
        guard minutes > 0 else { return nil }
        let goal = TimeInterval(minutes * 60)
        let current = sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.actualDuration }
        return StudyGoalProgress(currentSeconds: current, goalSeconds: goal, label: "Today")
    }

    static func weeklyProgress(from sessions: [StudySession]) -> StudyGoalProgress? {
        let minutes = weeklyGoalMinutes
        guard minutes > 0 else { return nil }
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return nil }
        let goal = TimeInterval(minutes * 60)
        let current = sessions
            .filter { $0.startedAt >= weekStart }
            .reduce(0) { $0 + $1.actualDuration }
        return StudyGoalProgress(currentSeconds: current, goalSeconds: goal, label: "This week")
    }
}

enum SubjectSorting {
    static let maxPinned = 3

    static func sorted(_ subjects: [Subject]) -> [Subject] {
        let pinned = subjects.filter(\.isPinned).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let rest = subjects.filter { !$0.isPinned }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return pinned + rest
    }

    @MainActor
    static func togglePin(_ subject: Subject, subjects: [Subject], in context: ModelContext) {
        if subject.isPinned {
            subject.isPinned = false
            try? context.save()
            return
        }
        let pinnedCount = subjects.filter(\.isPinned).count
        if pinnedCount >= maxPinned, let oldest = subjects.filter(\.isPinned).sorted(by: { $0.createdAt < $1.createdAt }).first {
            oldest.isPinned = false
        }
        subject.isPinned = true
        try? context.save()
    }
}
