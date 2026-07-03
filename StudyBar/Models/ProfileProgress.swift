import Foundation
import SwiftData

@Model
final class ProfileProgress {
    var totalXp: Int
    var totalSessions: Int
    var totalStudySeconds: TimeInterval
    var backfillVersion: Int
    var updatedAt: Date

    init(
        totalXp: Int = 0,
        totalSessions: Int = 0,
        totalStudySeconds: TimeInterval = 0,
        backfillVersion: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.totalXp = totalXp
        self.totalSessions = totalSessions
        self.totalStudySeconds = totalStudySeconds
        self.backfillVersion = backfillVersion
        self.updatedAt = updatedAt
    }
}
