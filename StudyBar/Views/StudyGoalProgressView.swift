import SwiftUI

struct StudyGoalProgressView: View {
    let progress: StudyGoalProgress
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: compact ? 3 : 4)
                Circle()
                    .trim(from: 0, to: progress.fraction)
                    .stroke(progress.isComplete ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: compact ? 3 : 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.35), value: progress.fraction)
                if compact {
                    Image(systemName: progress.isComplete ? "checkmark" : "target")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(progress.isComplete ? .green : .secondary)
                }
            }
            .frame(width: compact ? 28 : 36, height: compact ? 28 : 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(progress.label)
                    .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(StudyFormatting.duration(progress.currentSeconds)) / \(StudyFormatting.duration(progress.goalSeconds))")
                    .font(compact ? .caption.monospacedDigit() : .subheadline.monospacedDigit())
            }
            Spacer(minLength: 0)
        }
        .padding(compact ? 8 : 10)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
    }
}
