import SwiftUI
import SwiftData

struct ProfileDashboardView: View {
    @Query private var profiles: [ProfileProgress]
    @Query(sort: \SubjectProgress.totalXp, order: .reverse) private var subjectRows: [SubjectProgress]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    private var profile: ProfileProgress? { profiles.first }
    private var level: Int { GamificationEngine.level(forTotalXp: profile?.totalXp ?? 0) }
    private var xpProgress: (current: Int, needed: Int) {
        GamificationEngine.xpProgress(totalXp: profile?.totalXp ?? 0, level: level)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                profileHeader
                statsGrid
                if !subjectRows.isEmpty {
                    subjectSection
                }
            }
            .padding(24)
        }
        .navigationTitle("Profile")
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Level \(level)")
                    .font(.largeTitle.bold())
                Spacer()
                Text("\(profile?.totalXp ?? 0) XP")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(xpProgress.current), total: Double(xpProgress.needed))
                .tint(.accentColor)
            Text("\(xpProgress.needed - xpProgress.current) XP to level \(level + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard("Current Streak", "\(AnalyticsEngine.currentStreak(from: sessions)) days", "flame.fill")
            statCard("Best Streak", "\(AnalyticsEngine.longestStreak(from: sessions)) days", "flame")
            statCard("Hours Studied", StudyFormatting.duration(profile?.totalStudySeconds ?? 0), "clock.fill")
            statCard("Sessions", "\(profile?.totalSessions ?? 0)", "checkmark.circle.fill")
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subjects")
                .font(.headline)
            ForEach(subjectRows, id: \.persistentModelID) { row in
                SubjectProgressCard(row: row)
            }
        }
    }

    private func statCard(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct SubjectProgressCard: View {
    let row: SubjectProgress

    private var level: Int { GamificationEngine.level(forTotalXp: row.totalXp) }
    private var progress: (current: Int, needed: Int) {
        GamificationEngine.xpProgress(totalXp: row.totalXp, level: level)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(TimelineEngine.subjectColor(for: row.subjectName))
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(row.subjectName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("Lv \(level)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(progress.current), total: Double(progress.needed))
                    .controlSize(.small)
                HStack {
                    Text(StudyFormatting.duration(row.totalStudySeconds))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(row.totalXp) XP · \(row.totalSessions) sessions")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
    }
}
