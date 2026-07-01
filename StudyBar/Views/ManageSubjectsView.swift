import SwiftUI
import SwiftData

struct ManageSubjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @State private var newSubjectName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("New subject", text: $newSubjectName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addSubject)
                Button("Add", action: addSubject)
                    .disabled(newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            List {
                ForEach(subjects) { subject in
                    SubjectRow(subject: subject)
                }
            }
            .listStyle(.plain)
            .frame(height: 220)
        }
        .padding(16)
        .frame(width: 300)
        .navigationTitle("Manage Subjects")
    }

    private func addSubject() {
        let name = newSubjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(Subject(name: name))
        newSubjectName = ""
    }
}

private struct SubjectRow: View {
    @Bindable var subject: Subject
    @Environment(\.modelContext) private var modelContext
    @State private var newTopicName = ""
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(subject.topics.sorted(by: { $0.name < $1.name })) { topic in
                    TopicRow(topic: topic)
                }
                HStack {
                    TextField("New topic", text: $newTopicName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addTopic)
                    Button("Add", action: addTopic)
                        .disabled(newTopicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.leading, 8)
            .padding(.top, 4)
        } label: {
            HStack {
                TextField("Subject", text: $subject.name)
                    .textFieldStyle(.plain)
                Spacer()
                Button {
                    modelContext.delete(subject)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func addTopic() {
        let name = newTopicName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(Topic(name: name, subject: subject))
        newTopicName = ""
    }
}

private struct TopicRow: View {
    @Bindable var topic: Topic
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            TextField("Topic", text: $topic.name)
                .textFieldStyle(.plain)
            Spacer()
            Button {
                modelContext.delete(topic)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}
