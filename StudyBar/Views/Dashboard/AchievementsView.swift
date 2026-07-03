import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query(sort: \AchievementUnlock.unlockedAt, order: .reverse) private var unlocks: [AchievementUnlock]
    @State private var category: AchievementCategory?

    private var unlockedKeys: Set<String> {
        Set(unlocks.map { unlock in
            if let subject = unlock.subjectName { return "\(unlock.achievementId)|\(subject)" }
            return unlock.achievementId
        })
    }

    private var unlockedCount: Int { unlocks.count }
    private var totalDefinitions: Int {
        AchievementCatalog.global.count +
        (AchievementCatalog.subjectTemplates.count * max(1, uniqueSubjects.count))
    }

    @Query(sort: \SubjectProgress.subjectName) private var subjectRows: [SubjectProgress]
    private var uniqueSubjects: [String] { subjectRows.map(\.subjectName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            categoryPicker
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(filteredAchievements) { item in
                        achievementCard(item)
                    }
                }
            }
        }
        .padding(24)
        .navigationTitle("Achievements")
    }

    private struct AchievementItem: Identifiable {
        let id: String
        let definition: AchievementDefinition
        let subjectName: String?
        let unlocked: Bool
        let unlockedAt: Date?
    }

    private var filteredAchievements: [AchievementItem] {
        allAchievementItems.filter { item in
            guard let category else { return true }
            return item.definition.category == category
        }
    }

    private var allAchievementItems: [AchievementItem] {
        var items: [AchievementItem] = []
        let unlockMap = Dictionary(uniqueKeysWithValues: unlocks.map { unlock in
            (unlock.subjectName.map { "\(unlock.achievementId)|\($0)" } ?? unlock.achievementId, unlock.unlockedAt)
        })

        for definition in AchievementCatalog.global {
            let unlockedAt = unlockMap[definition.id]
            items.append(AchievementItem(
                id: definition.id,
                definition: definition,
                subjectName: nil,
                unlocked: unlockedAt != nil,
                unlockedAt: unlockedAt
            ))
        }

        for subject in uniqueSubjects {
            for definition in AchievementCatalog.subjectTemplates {
                let key = "\(definition.id)|\(subject)"
                let unlockedAt = unlockMap[key]
                items.append(AchievementItem(
                    id: key,
                    definition: definition,
                    subjectName: subject,
                    unlocked: unlockedAt != nil,
                    unlockedAt: unlockedAt
                ))
            }
        }
        return items
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unlockedCount) unlocked")
                    .font(.title2.bold())
                Text("Track your study milestones")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", selected: category == nil) { category = nil }
                ForEach(AchievementCategory.allCases) { cat in
                    filterChip(cat.title, selected: category == cat) { category = cat }
                }
            }
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func achievementCard(_ item: AchievementItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: item.definition.icon)
                .font(.title3)
                .foregroundStyle(item.unlocked ? .yellow : .secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.definition.displayTitle(subjectName: item.subjectName))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.unlocked ? .primary : .secondary)
                Text(item.definition.displayDetail(subjectName: item.subjectName))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if let date = item.unlockedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(item.unlocked ? Color.yellow.opacity(0.08) : Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(item.unlocked ? Color.yellow.opacity(0.25) : .clear, lineWidth: 1))
    }
}
