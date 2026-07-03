import SwiftUI
import SwiftData

struct SessionLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @State private var searchText = ""
    @State private var selectedIds = Set<PersistentIdentifier>()
    @State private var showDeleteSelectedConfirm = false
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

    private var selectedSessions: [StudySession] {
        filteredSessions.filter { selectedIds.contains($0.persistentModelID) }
    }

    private var shortSessions: [StudySession] {
        sessions.filter { $0.actualDuration < 5 * 60 }
    }

    private var allFilteredSelected: Bool {
        !filteredSessions.isEmpty && selectedIds.count == filteredSessions.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            selectionToolbar

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
                .onChange(of: searchText) { _, _ in
                    pruneSelection()
                }

            if filteredSessions.isEmpty {
                ContentUnavailableView(
                    sessions.isEmpty ? "No Sessions" : "No Matches",
                    systemImage: "list.bullet",
                    description: Text(sessions.isEmpty ? "Completed sessions appear here." : "Try a different search.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedIds) {
                    ForEach(filteredSessions, id: \.persistentModelID) { session in
                        sessionRow(session)
                            .tag(session.persistentModelID)
                            .contextMenu {
                                Button("Delete Session", role: .destructive) {
                                    deleteSessions([session])
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(24)
        .navigationTitle("Session Log")
        .confirmationDialog(
            "Delete \(selectedSessions.count) selected session\(selectedSessions.count == 1 ? "" : "s")?",
            isPresented: $showDeleteSelectedConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSessions(selectedSessions)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone. XP and achievements are recalculated.")
        }
        .confirmationDialog(
            "Delete \(shortSessions.count) short session\(shortSessions.count == 1 ? "" : "s")?",
            isPresented: $showDeleteShortConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSessions(shortSessions)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes all sessions shorter than 5 minutes. XP and achievements are recalculated.")
        }
    }

    private var selectionToolbar: some View {
        HStack(spacing: 10) {
            if !selectedIds.isEmpty {
                Text("\(selectedIds.count) selected")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Button("Delete Selected", role: .destructive) {
                    showDeleteSelectedConfirm = true
                }
                .controlSize(.small)
                Button("Clear") {
                    selectedIds.removeAll()
                }
                .controlSize(.small)
            } else {
                Text("Click rows to select · ⌘-click for multiple")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if !filteredSessions.isEmpty {
                Button(allFilteredSelected ? "Deselect All" : "Select All") {
                    if allFilteredSelected {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(filteredSessions.map(\.persistentModelID))
                    }
                }
                .controlSize(.small)
            }
        }
    }

    private func sessionRow(_ session: StudySession) -> some View {
        HStack(spacing: 10) {
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
        }
        .padding(.vertical, 2)
    }

    private func deleteSessions(_ targets: [StudySession]) {
        let deletedIds = Set(targets.map(\.persistentModelID))
        StudyDataStore.deleteSessions(targets, in: modelContext)
        selectedIds.subtract(deletedIds)
    }

    private func pruneSelection() {
        let visibleIds = Set(filteredSessions.map(\.persistentModelID))
        selectedIds = selectedIds.intersection(visibleIds)
    }
}
