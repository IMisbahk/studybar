import Foundation
import SwiftData

@Model
final class AchievementUnlock {
    var achievementId: String
    var subjectName: String?
    var unlockedAt: Date

    init(achievementId: String, subjectName: String? = nil, unlockedAt: Date = Date()) {
        self.achievementId = achievementId
        self.subjectName = subjectName
        self.unlockedAt = unlockedAt
    }
}
