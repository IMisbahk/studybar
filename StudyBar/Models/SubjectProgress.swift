import Foundation
import SwiftData

@Model
final class SubjectProgress {
    var subjectName: String
    var totalXp: Int
    var totalSessions: Int
    var totalStudySeconds: TimeInterval
    var updatedAt: Date

    init(
        subjectName: String,
        totalXp: Int = 0,
        totalSessions: Int = 0,
        totalStudySeconds: TimeInterval = 0,
        updatedAt: Date = Date()
    ) {
        self.subjectName = subjectName
        self.totalXp = totalXp
        self.totalSessions = totalSessions
        self.totalStudySeconds = totalStudySeconds
        self.updatedAt = updatedAt
    }
}
