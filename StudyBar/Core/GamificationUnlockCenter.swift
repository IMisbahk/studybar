import Foundation
import Observation

struct AchievementUnlockEvent: Equatable, Identifiable {
    let id: UUID
    let achievementId: String
    let title: String
    let detail: String
    let icon: String
    let subjectName: String?

    init(
        achievementId: String,
        title: String,
        detail: String,
        icon: String,
        subjectName: String? = nil
    ) {
        self.id = UUID()
        self.achievementId = achievementId
        self.title = title
        self.detail = detail
        self.icon = icon
        self.subjectName = subjectName
    }
}

@Observable
@MainActor
final class GamificationUnlockCenter {
    static let shared = GamificationUnlockCenter()

    private(set) var queue: [AchievementUnlockEvent] = []
    private(set) var current: AchievementUnlockEvent?

    private init() {}

    func enqueue(_ event: AchievementUnlockEvent) {
        queue.append(event)
        presentNextIfIdle()
    }

    func dismissCurrent() {
        current = nil
        presentNextIfIdle()
    }

    private func presentNextIfIdle() {
        guard current == nil, !queue.isEmpty else { return }
        current = queue.removeFirst()
    }
}
