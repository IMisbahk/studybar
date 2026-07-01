import SwiftUI
import SwiftData

struct IdleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var subjects: [Subject]

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
    }

    private var selectedMinutes: Int? {
        switch duration {
        case .preset(let minutes): return minutes
        case .custom: return Int(customMinutesText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("StudyBar")
                .font(.title3.bold())

            subjectSection
            if selectedSubject != nil {
                topicSection
            }
            durationSection
            startButton
        }
        .padding(16)
        .frame(width: 300)
        .onAppear {
            if selectedSubject == nil {
                selectedSubject = subjects.first
            }
        }
    }

    private var subjectSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Subject")
                .font(.caption)
                .foregroundStyle(.secondary)

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
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(subject as Subject?)
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

            Picker("Duration", selection: $duration) {
                Text("25 min").tag(DurationChoice.preset(25))
                Text("50 min").tag(DurationChoice.preset(50))
                Text("90 min").tag(DurationChoice.preset(90))
                Text("Custom").tag(DurationChoice.custom)
            }
            .labelsHidden()
            .pickerStyle(.segmented)

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
            Text("Start Session")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(selectedSubject == nil || (selectedMinutes ?? 0) <= 0)
    }

    private func startSession() {
        guard let subject = selectedSubject, let minutes = selectedMinutes, minutes > 0 else { return }
        NotificationManager.shared.fireSessionStarted(
            subjectName: subject.name,
            topicName: selectedTopic?.name,
            minutes: minutes
        )
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
