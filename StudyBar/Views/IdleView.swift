import SwiftUI
import SwiftData

struct IdleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]

    @State private var selectedSubject: Subject?
    @State private var selectedTopic: Topic?
    @State private var duration: DurationChoice = .preset(25)
    @State private var customMinutesText = ""
    @State private var addingSubject = false
    @State private var newSubjectName = ""
    @State private var addingTopic = false
    @State private var newTopicName = ""

    private enum DurationChoice: Hashable {
        case preset(Int)
        case custom
        case stopwatch
    }

    private var selectedMinutes: Int? {
        switch duration {
        case .preset(let minutes): return minutes
        case .custom: return Int(customMinutesText)
        case .stopwatch: return nil
        }
    }

    private var todayStudied: String {
        StudyFormatting.duration(StudyFormatting.todayTotal(from: sessions))
    }

    private var sortedSubjects: [Subject] {
        SubjectSorting.sorted(subjects)
    }

    private var pinnedSubjects: [Subject] {
        sortedSubjects.filter(\.isPinned)
    }

    private var suggestedMinutes: Int? {
        InsightsEngine.suggestedSessionMinutes(from: sessions)
    }

    private var dailyGoal: StudyGoalProgress? {
        StudyGoalHelper.dailyProgress(from: sessions)
    }

    private var recentSubjects: [String] {
        StudyFormatting.recentSubjectNames(from: sessions)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if let dailyGoal {
                StudyGoalProgressView(progress: dailyGoal, compact: true)
            }
            if subjects.isEmpty {
                emptyState
            } else {
                if !pinnedSubjects.isEmpty {
                    pinnedSection
                }
                if !recentSubjects.isEmpty {
                    recentSection
                }
                subjectSection
                if selectedSubject != nil {
                    topicSection
                }
                durationSection
                startButton
            }
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            applySuggestedDurationIfNeeded()
            if selectedSubject == nil {
                selectedSubject = sortedSubjects.first
            }
        }
        .onChange(of: sessions.count) { _, _ in
            applySuggestedDurationIfNeeded()
        }
    }

    private func applySuggestedDurationIfNeeded() {
        guard let suggested = suggestedMinutes else { return }
        if case .preset(25) = duration {
            duration = .preset(suggested)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            AppLogoView(size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("StudyBar")
                    .font(.title3.bold())
                Text("Focused study sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            StatPill(label: "Today", value: todayStudied)
            Image(systemName: "books.vertical")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
            Text("Add your first subject")
                .font(.subheadline.weight(.medium))
            Text("e.g. Maths, Physics, Chemistry")
                .font(.caption)
                .foregroundStyle(.secondary)
            addFirstSubjectField
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var addFirstSubjectField: some View {
        HStack {
            TextField("Subject name", text: $newSubjectName)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addSubject)
            Button("Add", action: addSubject)
                .buttonStyle(.borderedProminent)
                .disabled(trimmed(newSubjectName).isEmpty)
        }
    }

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pinned")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(pinnedSubjects) { subject in
                        Button {
                            selectedSubject = subject
                            selectedTopic = nil
                        } label: {
                            Label(subject.name, systemImage: "star.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(selectedSubject?.persistentModelID == subject.persistentModelID ? .accentColor : .secondary)
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(recentSubjects, id: \.self) { name in
                        Button(name) {
                            selectedSubject = subjects.first { $0.name == name }
                            selectedTopic = nil
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(selectedSubject?.name == name ? .accentColor : .secondary)
                    }
                }
            }
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Subject")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                StatPill(label: "Today", value: todayStudied)
            }

            if addingSubject {
                HStack {
                    TextField("New subject", text: $newSubjectName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addSubject)
                    Button("Add", action: addSubject)
                        .disabled(trimmed(newSubjectName).isEmpty)
                    Button("Cancel") {
                        addingSubject = false
                        newSubjectName = ""
                    }
                }
            } else {
                HStack {
                    Picker("Subject", selection: $selectedSubject) {
                        Text("None").tag(nil as Subject?)
                        ForEach(sortedSubjects) { subject in
                            HStack {
                                if subject.isPinned {
                                    Image(systemName: "star.fill")
                                }
                                Text(subject.name)
                            }
                            .tag(subject as Subject?)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedSubject) { _, _ in selectedTopic = nil }

                    Button {
                        addingSubject = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addSubject() {
        let name = trimmed(newSubjectName)
        guard !name.isEmpty else { return }
        let subject = Subject(name: name)
        modelContext.insert(subject)
        selectedSubject = subject
        newSubjectName = ""
        addingSubject = false
    }

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Topic (optional)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if addingTopic {
                HStack {
                    TextField("New topic", text: $newTopicName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addTopic)
                    Button("Add", action: addTopic)
                        .disabled(trimmed(newTopicName).isEmpty)
                    Button("Cancel") {
                        addingTopic = false
                        newTopicName = ""
                    }
                }
            } else {
                HStack {
                    Picker("Topic", selection: $selectedTopic) {
                        Text("None").tag(nil as Topic?)
                        ForEach((selectedSubject?.topics ?? []).sorted(by: { $0.name < $1.name })) { topic in
                            Text(topic.name).tag(topic as Topic?)
                        }
                    }
                    .labelsHidden()

                    Button {
                        addingTopic = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func addTopic() {
        let name = trimmed(newTopicName)
        guard !name.isEmpty, let subject = selectedSubject else { return }
        let topic = Topic(name: name, subject: subject)
        modelContext.insert(topic)
        selectedTopic = topic
        newTopicName = ""
        addingTopic = false
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Duration")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let suggested = suggestedMinutes {
                Button {
                    duration = .preset(suggested)
                } label: {
                    Label("\(suggested) min — suggested for you", systemImage: "sparkles")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(duration == .preset(suggested) ? .accentColor : .secondary)
            }

            Picker("Duration", selection: $duration) {
                Text("25").tag(DurationChoice.preset(25))
                Text("50").tag(DurationChoice.preset(50))
                Text("90").tag(DurationChoice.preset(90))
                Text("∞").tag(DurationChoice.stopwatch)
                Text("Custom").tag(DurationChoice.custom)
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            if duration == .stopwatch {
                Text("Open-ended stopwatch — stop when you're done.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if duration == .custom {
                TextField("Minutes", text: $customMinutesText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var startButton: some View {
        Button {
            startSession()
        } label: {
            Label("Start Session", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .keyboardShortcut(.return, modifiers: .command)
        .disabled(selectedSubject == nil || (duration != .stopwatch && (selectedMinutes ?? 0) <= 0))
    }

    private func startSession() {
        guard let subject = selectedSubject else { return }
        if duration == .stopwatch {
            sessionManager.startStopwatch(subjectName: subject.name, topicName: selectedTopic?.name)
            return
        }
        guard let minutes = selectedMinutes, minutes > 0 else { return }
        sessionManager.start(subjectName: subject.name, topicName: selectedTopic?.name, minutes: minutes)
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
