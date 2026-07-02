import SwiftUI
import SwiftData

struct DashboardHistoryView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var searchText = ""

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

    private var groupedByDay: [(day: Date, sessions: [StudySession])] {
        Dictionary(grouping: filteredSessions) { calendar.startOfDay(for: $0.startedAt) }
            .map { (day: $0.key, sessions: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Search subjects, topics, or notes", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if filteredSessions.isEmpty {
                ContentUnavailableView(
                    sessions.isEmpty ? "No Sessions Yet" : "No Matches",
                    systemImage: "clock.arrow.circlepath",
                    description: Text(sessions.isEmpty ? "Completed sessions appear here." : "Try a different search.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedByDay, id: \.day) { group in
                        Section(dayTitle(group.day)) {
                            ForEach(group.sessions, id: \.persistentModelID) { session in
                                sessionRow(session)
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .navigationTitle("History")
    }

    private func dayTitle(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    private func sessionRow(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.subjectName)
                    .font(.headline)
                if let topic = session.topicName {
                    Text("· \(topic)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(StudyFormatting.duration(session.actualDuration))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                Image(systemName: sessionIcon(session))
                    .foregroundStyle(session.completed ? .green : .orange)
                    .font(.caption)
            }
            HStack {
                Text(session.startedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if let notes = session.notes, !notes.isEmpty {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func sessionIcon(_ session: StudySession) -> String {
        if session.openEnded { return "stopwatch" }
        return session.completed ? "checkmark.circle.fill" : "xmark.circle"
    }
}
