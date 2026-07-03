import SwiftUI
import SwiftData

struct InsightsDashboardView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var snapshot = InsightsSnapshot.build(from: [])

    private var snapshotKey: String {
        let latest = sessions.first?.startedAt.timeIntervalSince1970 ?? 0
        return "\(sessions.count)-\(latest)"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                if snapshot.hasEnoughData {
                    summarySection
                    if !snapshot.insights.isEmpty {
                        insightsSection
                    }
                } else {
                    emptyState
                }
            }
            .padding(24)
        }
        .navigationTitle("Insights")
        .task(id: snapshotKey) {
            snapshot = InsightsSnapshot.build(from: sessions)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Smart Insights")
                .font(.title2.bold())
            Text("Local patterns from your study history — no cloud, no chatbot.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryCard(
                title: "This Week",
                icon: "calendar",
                text: snapshot.weeklySummary
            )
            summaryCard(
                title: "This Month",
                icon: "calendar.badge.clock",
                text: snapshot.monthlySummary
            )
            if let minutes = snapshot.suggestedSessionMinutes {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .foregroundStyle(.tint)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Suggested preset")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(minutes) minutes matches your typical session length")
                            .font(.subheadline)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func summaryCard(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns & tips")
                .font(.headline)
            ForEach(InsightCategory.allCases, id: \.self) { category in
                let items = snapshot.insights.filter { $0.category == category }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        ForEach(items) { insight in
                            insightCard(insight)
                        }
                    }
                }
            }
        }
    }

    private func insightCard(_ insight: StudyInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.systemImage)
                .font(.title3)
                .foregroundStyle(tint(for: insight.category))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = insight.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Not enough data yet", systemImage: "sparkles")
                .font(.headline)
            Text("Complete at least 3 sessions and insights will appear here — focus windows, consistency trends, burnout warnings, and weekly summaries.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private func tint(for category: InsightCategory) -> Color {
        switch category {
        case .pattern: .accentColor
        case .suggestion: .orange
        case .warning: .red
        case .summary: .purple
        }
    }
}
