import SwiftUI
import SwiftData

// compact timeline for menu-bar popover — full replay lives in dashboard
struct HistoryView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var searchText = ""
    @State private var hoveredSessionId: PersistentIdentifier?

    private var calendar: Calendar { .current }

    private var filteredSessions: [StudySession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return sessions }
        return sessions.filter { session in
            session.subjectName.lowercased().contains(query)
                || (session.topicName?.lowercased().contains(query) ?? false)
                || (session.notes?.lowercased().contains(query) ?? false)
        }
    }

    private var recentSessions: [StudySession] {
        guard let cutoff = calendar.date(byAdding: .day, value: -13, to: calendar.startOfDay(for: Date())) else {
            return filteredSessions
        }
        return filteredSessions.filter { $0.startedAt >= cutoff }
    }

    private var days: [TimelineDayRow] {
        TimelineEngine.buildDays(from: recentSessions, zoom: .compact)
    }

    private var todayTotal: TimeInterval {
        filteredSessions
            .filter { calendar.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.actualDuration }
    }

    private var weekTotal: TimeInterval {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return filteredSessions.filter { $0.startedAt >= weekStart }.reduce(0) { $0 + $1.actualDuration }
    }

    private var hoveredItem: TimelineSessionItem? {
        guard let hoveredSessionId else { return nil }
        for day in days {
            if let item = day.sessions.first(where: { $0.id == hoveredSessionId }) {
                return item
            }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Timeline")
                    .font(.title3.bold())
                Spacer()
                Button("Open full") {
                    DashboardWindowController.shared.show(section: .timeline)
                }
                .font(.caption)
                .buttonStyle(.link)
            }

            if sessions.isEmpty {
                Text("No sessions yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            } else {
                HStack(spacing: 8) {
                    miniStat("Today", todayTotal)
                    miniStat("Week", weekTotal)
                }

                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if let hoveredItem {
                    TimelineSessionTooltip(item: hoveredItem)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))
                }

                if days.isEmpty {
                    Text("No matches")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                                TimelineDayRowView(
                                    day: day,
                                    zoom: .compact,
                                    isFirst: index == 0,
                                    isLast: index == days.count - 1,
                                    hoveredSessionId: $hoveredSessionId
                                )
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                }
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private func miniStat(_ title: String, _ value: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(StudyFormatting.duration(value))
                .font(.caption.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }
}
