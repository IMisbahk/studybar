import SwiftUI
import SwiftData

struct SessionLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var searchText = ""
    @State private var showDeleteShortConfirm = false

    private var filteredSessions: [StudySession] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return sessions }
        return sessions.filter { session in
            session.subjectName.lowercased().contains(query)
                || (session.topicName?.lowercased().contains(query) ?? false)
                || (session.notes?.lowercased().contains(query) ?? false)
        }
    }

    private var shortSessions: [StudySession] {
        sessions.filter { $0.actualDuration < 5 * 60 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !shortSessions.isEmpty {
                HStack {
                    Text("\(shortSessions.count) session\(shortSessions.count == 1 ? "" : "s") under 5 min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Delete all under 5 min", role: .destructive) {
                        showDeleteShortConfirm = true
                    }
                    .controlSize(.small)
                }
            }

            TextField("Search sessions", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if filteredSessions.isEmpty {
                ContentUnavailableView(
                    sessions.isEmpty ? "No Sessions" : "No Matches",
                    systemImage: "list.bullet",
                    description: Text(sessions.isEmpty ? "Completed sessions appear here." : "Try a different search.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredSessions, id: \.persistentModelID) { session in
                        sessionRow(session)
                            .contextMenu {
                                Button("Delete Session", role: .destructive) {
                                    delete(session)
                                }
                            }
                    }
                    .onDelete(perform: deleteAtOffsets)
                }
                .listStyle(.inset)
            }
        }
        .padding(24)
        .navigationTitle("Session Log")
        .confirmationDialog(
            "Delete \(shortSessions.count) short session\(shortSessions.count == 1 ? "" : "s")?",
            isPresented: $showDeleteShortConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                StudyDataStore.deleteSessions(shortSessions, in: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes all sessions shorter than 5 minutes. XP and achievements are recalculated.")
        }
    }

    private func sessionRow(_ session: StudySession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.subjectName)
                    .font(.headline)
                if let topic = session.topicName, !topic.isEmpty {
                    Text("· \(topic)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(StudyFormatting.duration(session.actualDuration))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if session.completed {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Label("Stopped early", systemImage: "stop.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func delete(_ session: StudySession) {
        StudyDataStore.deleteSession(session, in: modelContext)
    }

    private func deleteAtOffsets(_ offsets: IndexSet) {
        let targets = offsets.map { filteredSessions[$0] }
        StudyDataStore.deleteSessions(targets, in: modelContext)
    }
}
