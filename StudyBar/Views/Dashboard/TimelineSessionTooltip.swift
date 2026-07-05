import SwiftUI

struct TimelineSessionTooltip: View {
    let item: TimelineSessionItem
    var compact = false

    private var session: StudySession { item.session }

    var body: some View {
        if compact {
            compactBody
        } else {
            fullBody
        }
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Circle()
                    .fill(TimelineEngine.subjectColor(for: session.subjectName))
                    .frame(width: 8, height: 8)
                Text(session.subjectName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let topic = session.topicName {
                    Text("· \(topic)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            detailRow("Start", session.startedAt.formatted(date: .omitted, time: .shortened))
            detailRow("Duration", StudyFormatting.duration(session.actualDuration))
        }
        .padding(10)
        .frame(width: 220)
    }

    private var fullBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Circle()
                    .fill(TimelineEngine.subjectColor(for: session.subjectName))
                    .frame(width: 8, height: 8)
                Text(session.subjectName)
                    .font(.subheadline.weight(.semibold))
                if let topic = session.topicName {
                    Text("· \(topic)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(StudyFormatting.duration(session.actualDuration))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Divider()

            detailRow("Start", session.startedAt.formatted(date: .omitted, time: .shortened))
            detailRow("End", session.endedAt.formatted(date: .omitted, time: .shortened))
            detailRow("Duration", StudyFormatting.duration(session.actualDuration))

            if let notes = session.notes, !notes.isEmpty {
                Divider()
                Text("Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(notes)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !item.pauses.isEmpty {
                Divider()
                Text("Pauses")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(item.pauses) { pause in
                    HStack {
                        Text(pause.kind.label)
                            .font(.caption2)
                        Spacer()
                        Text("\(pause.startedAt.formatted(date: .omitted, time: .shortened)) → \(pause.endedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !item.pauses.isEmpty {
                Text("Resume points")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                ForEach(item.pauses) { pause in
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(pause.resumeAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption2.monospacedDigit())
                    }
                }
            }

            if !item.gapsAfter.isEmpty {
                Divider()
                Text("Breaks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(item.gapsAfter) { gap in
                    HStack {
                        Text("Between sessions")
                            .font(.caption2)
                        Spacer()
                        Text(StudyFormatting.duration(gap.duration))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !session.completed {
                Label(session.openEnded ? "Stopwatch session" : "Stopped early", systemImage: session.openEnded ? "stopwatch" : "xmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .frame(minWidth: 240, maxWidth: 320)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }
}
