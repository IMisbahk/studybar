import Foundation

enum StudyFormatting {
    static func duration(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "0m"
    }

    static func todayTotal(from sessions: [StudySession]) -> TimeInterval {
        let calendar = Calendar.current
        return sessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.actualDuration }
    }

    static func recentSubjectNames(from sessions: [StudySession], limit: Int = 5) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for session in sessions {
            guard !seen.contains(session.subjectName) else { continue }
            seen.insert(session.subjectName)
            result.append(session.subjectName)
            if result.count >= limit { break }
        }
        return result
    }
}
