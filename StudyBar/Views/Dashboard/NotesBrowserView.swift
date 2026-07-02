import SwiftUI
import SwiftData

struct NotesBrowserView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var searchText = ""

    private var notedSessions: [StudySession] {
        let base = AnalyticsEngine.sessionsWithNotes(from: sessions)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return base }
        return base.filter { session in
            session.subjectName.lowercased().contains(query)
                || (session.topicName?.lowercased().contains(query) ?? false)
                || (session.notes?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Search notes", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if notedSessions.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "note.text",
                    description: Text("Session notes you add during study appear here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(notedSessions, id: \.persistentModelID) { session in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(session.subjectName)
                                .font(.headline)
                            if let topic = session.topicName {
                                Text("· \(topic)")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(session.notes ?? "")
                            .font(.body)
                            .textSelection(.enabled)
                        Text("\(StudyFormatting.duration(session.actualDuration)) studied")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .navigationTitle("Notes")
    }
}
