import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    @State private var zoom: TimelineZoom = .focus
    @State private var dateRange: TimelineDateRange = .all
    @State private var searchText = ""
    @State private var selectedSubjects: Set<String> = []
    @State private var completedOnly = false
    @State private var hoveredSessionId: PersistentIdentifier?

    private var allSubjects: [String] {
        TimelineEngine.allSubjectNames(from: sessions)
    }

    private var filteredSessions: [StudySession] {
        TimelineEngine.filter(
            sessions: sessions,
            searchText: searchText,
            subjects: selectedSubjects,
            dateRange: dateRange,
            completedOnly: completedOnly
        )
    }

    private var days: [TimelineDayRow] {
        TimelineEngine.buildDays(from: filteredSessions, zoom: zoom)
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
        VStack(alignment: .leading, spacing: 16) {
            toolbar
            if let hoveredItem {
                TimelineSessionTooltip(item: hoveredItem)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 1))
            }
            if days.isEmpty {
                ContentUnavailableView(
                    sessions.isEmpty ? "No Sessions Yet" : "No Matches",
                    systemImage: "timeline.selection",
                    description: Text(sessions.isEmpty ? "Start a session to build your timeline." : "Try different filters.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                            TimelineDayRowView(
                                day: day,
                                zoom: zoom,
                                isFirst: index == 0,
                                isLast: index == days.count - 1,
                                hoveredSessionId: $hoveredSessionId
                            )
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(24)
        .navigationTitle("Timeline")
    }

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Picker("Zoom", selection: $zoom) {
                    ForEach(TimelineZoom.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)

                Picker("Range", selection: $dateRange) {
                    ForEach(TimelineDateRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .frame(maxWidth: 160)

                Toggle("Completed only", isOn: $completedOnly)
                    .toggleStyle(.checkbox)
            }

            HStack(spacing: 12) {
                TextField("Search subjects, topics, or notes", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                Menu {
                    Button(selectedSubjects.isEmpty ? "All subjects" : "Clear filter") {
                        selectedSubjects = []
                    }
                    Divider()
                    ForEach(allSubjects, id: \.self) { name in
                        Button {
                            toggleSubject(name)
                        } label: {
                            HStack {
                                Text(name)
                                if selectedSubjects.contains(name) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label(
                        selectedSubjects.isEmpty ? "All subjects" : "\(selectedSubjects.count) subject\(selectedSubjects.count == 1 ? "" : "s")",
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
            }

            if !allSubjects.isEmpty {
                subjectLegend
            }
        }
    }

    private var subjectLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allSubjects, id: \.self) { name in
                    let selected = selectedSubjects.isEmpty || selectedSubjects.contains(name)
                    Button {
                        toggleSubject(name)
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(TimelineEngine.subjectColor(for: name))
                                .frame(width: 8, height: 8)
                            Text(name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.05), in: Capsule())
                        .opacity(selected ? 1 : 0.45)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggleSubject(_ name: String) {
        if selectedSubjects.contains(name) {
            selectedSubjects.remove(name)
        } else {
            selectedSubjects.insert(name)
        }
    }
}
