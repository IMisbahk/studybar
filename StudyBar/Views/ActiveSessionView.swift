import SwiftUI

struct ActiveSessionView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var completionBounce = false

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
                ProgressRingView(
                    progress: sessionManager.progress,
                    lineWidth: 6,
                    isPaused: sessionManager.phase == .paused,
                    isUrgent: sessionManager.isUrgent
                )
                .frame(width: 120, height: 120)
                .scaleEffect(completionBounce ? 1.08 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.5), value: completionBounce)

                VStack(spacing: 2) {
                    Text(sessionManager.remainingText)
                        .font(.system(size: 28, weight: .semibold).monospacedDigit())
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9), value: sessionManager.remainingText)
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

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("What are you working on?", text: Bindable(sessionManager).draftNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
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
                .keyboardShortcut("p", modifiers: [.option, .command])

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
        .onChange(of: sessionManager.lastCompletion?.token) { _, token in
            guard token != nil, !reduceMotion else { return }
            completionBounce = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                completionBounce = false
            }
        }
    }
}
