import SwiftUI
import SwiftData

struct DashboardOverviewView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @Environment(SessionManager.self) private var sessionManager

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                statsGrid
                if !subjectTotals.isEmpty {
                    subjectBreakdown
                }
                sessionStatusCard
            }
            .padding(24)
        }
        .navigationTitle("Overview")
    }

    private var header: some View {
        HStack(spacing: 14) {
            AppLogoView(size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text("Study Dashboard")
                    .font(.title2.bold())
                Text("Your study activity at a glance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            overviewCard(title: "Today", value: StudyFormatting.duration(todayTotal), icon: "sun.max.fill")
            overviewCard(title: "This Week", value: StudyFormatting.duration(weekTotal), icon: "calendar")
            overviewCard(title: "This Month", value: StudyFormatting.duration(monthTotal), icon: "calendar.badge.clock")
            overviewCard(title: "Daily Avg", value: StudyFormatting.duration(dailyAverage), icon: "chart.line.uptrend.xyaxis")
        }
    }

    private func overviewCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private var subjectBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By Subject")
                .font(.headline)
            ForEach(subjectTotals.prefix(8), id: \.name) { item in
                HStack {
                    Text(item.name)
                    Spacer()
                    Text(StudyFormatting.duration(item.duration))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.subheadline)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
    }

    private var sessionStatusCard: some View {
        Group {
            switch sessionManager.phase {
            case .idle:
                Label("No active session — use the menu bar to start studying", systemImage: "timer")
                    .foregroundStyle(.secondary)
            case .running:
                Label {
                    if sessionManager.isStopwatch {
                        Text("Stopwatch running: \(sessionManager.elapsedText) — \(sessionManager.subjectName)")
                    } else {
                        Text("Session running: \(sessionManager.remainingText) left — \(sessionManager.subjectName)")
                    }
                } icon: {
                    Image(systemName: sessionManager.isStopwatch ? "stopwatch" : "timer")
                        .foregroundStyle(.green)
                }
            case .paused:
                Label("Session paused — \(sessionManager.subjectName)", systemImage: "pause.circle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.subheadline)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
    }

    private var todayTotal: TimeInterval {
        sessions.filter { calendar.isDateInToday($0.startedAt) }.reduce(0) { $0 + $1.actualDuration }
    }

    private var weekTotal: TimeInterval {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return sessions.filter { $0.startedAt >= weekStart }.reduce(0) { $0 + $1.actualDuration }
    }

    private var monthTotal: TimeInterval {
        guard let monthStart = calendar.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return sessions.filter { $0.startedAt >= monthStart }.reduce(0) { $0 + $1.actualDuration }
    }

    private var dailyAverage: TimeInterval {
        guard let firstDate = sessions.map(\.startedAt).min() else { return 0 }
        let dayCount = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: firstDate),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        let total = sessions.reduce(0) { $0 + $1.actualDuration }
        return total / Double(max(1, dayCount + 1))
    }

    private var subjectTotals: [(name: String, duration: TimeInterval)] {
        Dictionary(grouping: sessions, by: \.subjectName)
            .map { (name: $0.key, duration: $0.value.reduce(0) { $0 + $1.actualDuration }) }
            .sorted { $0.duration > $1.duration }
    }
}
