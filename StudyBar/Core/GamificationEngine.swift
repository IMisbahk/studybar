import Foundation
import SwiftData

enum PlanetTier: Int, CaseIterable {
    case seedling = 1
    case grown
    case rings
    case moons
    case stars
    case nebula
    case constellation

    var title: String {
        switch self {
        case .seedling: "Seedling"
        case .grown: "Growing"
        case .rings: "Ringed"
        case .moons: "Lunar"
        case .stars: "Stellar"
        case .nebula: "Nebula"
        case .constellation: "Constellation"
        }
    }

    static func from(hours: Double) -> PlanetTier {
        switch hours {
        case 500...: return .constellation
        case 250..<500: return .nebula
        case 100..<250: return .stars
        case 50..<100: return .moons
        case 20..<50: return .rings
        case 5..<20: return .grown
        default: return .seedling
        }
    }
}

enum GamificationEngine {
    static let currentBackfillVersion = AchievementCatalog.backfillVersion

    static func xp(from duration: TimeInterval) -> Int {
        max(0, Int(duration / 60))
    }

    static func xpRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(100.0 * pow(Double(level - 1), 1.5))
    }

    static func level(forTotalXp xp: Int) -> Int {
        var level = 1
        while xp >= xpRequired(forLevel: level + 1) {
            level += 1
        }
        return level
    }

    static func xpProgress(totalXp: Int, level: Int) -> (current: Int, needed: Int) {
        let floor = xpRequired(forLevel: level)
        let ceiling = xpRequired(forLevel: level + 1)
        return (totalXp - floor, max(1, ceiling - floor))
    }

    static func backfillIfNeeded(in context: ModelContext) {
        let profile = fetchOrCreateProfile(in: context)
        guard profile.backfillVersion < currentBackfillVersion else { return }
        rebuildAll(in: context)
        profile.backfillVersion = currentBackfillVersion
        profile.updatedAt = Date()
    }

    static func process(session: StudySession, in context: ModelContext) {
        let xpEarned = xp(from: session.actualDuration)
        guard xpEarned > 0 else { return }

        let profile = fetchOrCreateProfile(in: context)
        profile.totalXp += xpEarned
        profile.totalSessions += 1
        profile.totalStudySeconds += session.actualDuration
        profile.updatedAt = Date()

        let subject = fetchOrCreateSubjectProgress(name: session.subjectName, in: context)
        subject.totalXp += xpEarned
        subject.totalSessions += 1
        subject.totalStudySeconds += session.actualDuration
        subject.updatedAt = Date()

        evaluateAchievements(in: context, triggering: session)
    }

    static func rebuildAll(in context: ModelContext) {
        let sessions = (try? context.fetch(FetchDescriptor<StudySession>())) ?? []
        let profile = fetchOrCreateProfile(in: context)
        profile.totalXp = 0
        profile.totalSessions = 0
        profile.totalStudySeconds = 0

        let existingSubjects = (try? context.fetch(FetchDescriptor<SubjectProgress>())) ?? []
        for row in existingSubjects { context.delete(row) }

        for session in sessions {
            let earned = xp(from: session.actualDuration)
            profile.totalXp += earned
            profile.totalSessions += 1
            profile.totalStudySeconds += session.actualDuration

            let subject = fetchOrCreateSubjectProgress(name: session.subjectName, in: context)
            subject.totalXp += earned
            subject.totalSessions += 1
            subject.totalStudySeconds += session.actualDuration
        }
        profile.updatedAt = Date()

        let unlocks = (try? context.fetch(FetchDescriptor<AchievementUnlock>())) ?? []
        let previouslyUnlockedKeys = Set(unlocks.map { unlockKey(for: $0) })
        for unlock in unlocks { context.delete(unlock) }

        evaluateAchievements(in: context, triggering: nil, suppressNotificationKeys: previouslyUnlockedKeys)
    }

    private static func evaluateAchievements(
        in context: ModelContext,
        triggering: StudySession?,
        suppressNotificationKeys: Set<String> = []
    ) {
        let sessions = (try? context.fetch(FetchDescriptor<StudySession>())) ?? []
        let profile = fetchOrCreateProfile(in: context)
        let subjects = (try? context.fetch(FetchDescriptor<SubjectProgress>())) ?? []
        let unlocks = (try? context.fetch(FetchDescriptor<AchievementUnlock>())) ?? []
        let unlockedKeys = Set(unlocks.map { unlockKey(for: $0) })

        let snapshot = GamificationSnapshot(
            sessions: sessions,
            profile: profile,
            subjects: subjects,
            unlockedKeys: unlockedKeys,
            triggeringSession: triggering
        )

        var newEvents: [AchievementUnlockEvent] = []

        for definition in AchievementCatalog.global {
            guard !snapshot.isUnlocked(achievementId: definition.id, subjectName: nil) else { continue }
            guard definition.evaluate(snapshot, nil) else { continue }
            let unlock = AchievementUnlock(achievementId: definition.id)
            context.insert(unlock)
            let key = unlockKey(for: unlock)
            guard !suppressNotificationKeys.contains(key) else { continue }
            newEvents.append(AchievementUnlockEvent(
                achievementId: definition.id,
                title: definition.title,
                detail: definition.detail,
                icon: definition.icon
            ))
        }

        for subjectName in snapshot.subjectNames() {
            for definition in AchievementCatalog.subjectTemplates {
                guard !snapshot.isUnlocked(achievementId: definition.id, subjectName: subjectName) else { continue }
                guard definition.evaluate(snapshot, subjectName) else { continue }
                let unlock = AchievementUnlock(achievementId: definition.id, subjectName: subjectName)
                context.insert(unlock)
                let key = unlockKey(for: unlock)
                guard !suppressNotificationKeys.contains(key) else { continue }
                newEvents.append(AchievementUnlockEvent(
                    achievementId: definition.id,
                    title: definition.displayTitle(subjectName: subjectName),
                    detail: definition.displayDetail(subjectName: subjectName),
                    icon: definition.icon,
                    subjectName: subjectName
                ))
            }
        }

        if !newEvents.isEmpty {
            Task { @MainActor in
                for event in newEvents {
                    GamificationUnlockCenter.shared.enqueue(event)
                }
            }
        }
    }

    private static func unlockKey(for unlock: AchievementUnlock) -> String {
        if let subject = unlock.subjectName { return "\(unlock.achievementId)|\(subject)" }
        return unlock.achievementId
    }

    private static func fetchOrCreateProfile(in context: ModelContext) -> ProfileProgress {
        if let existing = try? context.fetch(FetchDescriptor<ProfileProgress>()).first {
            return existing
        }
        let profile = ProfileProgress()
        context.insert(profile)
        return profile
    }

    private static func fetchOrCreateSubjectProgress(name: String, in context: ModelContext) -> SubjectProgress {
        var descriptor = FetchDescriptor<SubjectProgress>(
            predicate: #Predicate { $0.subjectName == name }
        )
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let row = SubjectProgress(subjectName: name)
        context.insert(row)
        return row
    }
}
