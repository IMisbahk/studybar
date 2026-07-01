import SwiftUI

struct ActiveSessionView: View {
    @Environment(SessionManager.self) private var sessionManager

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
                Text(sessionManager.remainingText)
                    .font(.system(size: 28, weight: .semibold).monospacedDigit())
            }

            if sessionManager.phase == .paused {
                Text("Paused")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("+5 min") { sessionManager.extend(byMinutes: 5) }
                Button("+10 min") { sessionManager.extend(byMinutes: 10) }
            }
            .buttonStyle(.bordered)

            HStack(spacing: 8) {
                Button(sessionManager.phase == .paused ? "Resume" : "Pause") {
                    sessionManager.phase == .paused ? sessionManager.resume() : sessionManager.pause()
                }
                .frame(maxWidth: .infinity)

                Button("Stop") {
                    sessionManager.stop()
                }
                .tint(.red)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(16)
        .frame(width: 300)
    }
}
