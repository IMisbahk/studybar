import SwiftUI

struct ActiveSessionView: View {
    @Environment(SessionManager.self) private var sessionManager

    private var elapsed: TimeInterval {
        max(0, sessionManager.plannedDuration - sessionManager.remaining)
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(sessionManager.subjectName)
                    .font(.headline)
                if let topicName = sessionManager.topicName, !topicName.isEmpty {
                    Text(topicName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            ZStack {
                ProgressRingView(progress: sessionManager.progress, lineWidth: 6)
                    .frame(width: 120, height: 120)
                VStack(spacing: 2) {
                    Text(sessionManager.remainingText)
                        .font(.system(size: 28, weight: .semibold).monospacedDigit())
                    Text("remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Elapsed \(StudyFormatting.duration(elapsed)) · Planned \(StudyFormatting.duration(sessionManager.plannedDuration))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if sessionManager.phase == .paused {
                Label("Paused", systemImage: "pause.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 8) {
                Button("+5 min") { sessionManager.extend(byMinutes: 5) }
                Button("+10 min") { sessionManager.extend(byMinutes: 10) }
            }
            .buttonStyle(.bordered)

            HStack(spacing: 8) {
                Button {
                    sessionManager.phase == .paused ? sessionManager.resume() : sessionManager.pause()
                } label: {
                    Label(sessionManager.phase == .paused ? "Resume" : "Pause", systemImage: sessionManager.phase == .paused ? "play.fill" : "pause.fill")
                        .frame(maxWidth: .infinity)
                }

                Button {
                    sessionManager.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.red)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(16)
        .frame(width: 300)
    }
}
