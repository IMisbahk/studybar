import SwiftUI

struct HeatmapDayTooltip: View {
    let detail: DayStudyDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(detail.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(StudyFormatting.duration(detail.totalSeconds))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Divider()
            ForEach(detail.sessions) { session in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.subjectName)
                            .font(.caption.weight(.medium))
                        if let topic = session.topicName {
                            Text(topic)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(StudyFormatting.duration(session.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(minWidth: 180, maxWidth: 240)
    }
}
