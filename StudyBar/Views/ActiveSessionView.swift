import SwiftUI

struct ActiveSessionView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(\.studyTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("timerTypographyRounded") private var timerTypographyRounded = false

    @State private var completionBounce = false

    var body: some View {
        VStack(spacing: 10) {
            timingBlock
            notesBlock
            AmbientSoundControls(compact: true)
            if !sessionManager.isStopwatch {
                extendButtons
            }
            controlButtons
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

    @ViewBuilder
    private var timingBlock: some View {
        VStack(spacing: 8) {
            ZStack {
                if sessionManager.isStopwatch {
                    Circle()
                        .stroke(theme.accent.opacity(sessionManager.phase == .paused ? 0.25 : 0.5), lineWidth: 6)
                        .frame(width: 120, height: 120)
                        .opacity(sessionManager.phase == .paused ? 0.6 : 1)
                } else {
                    ProgressRingView(
                        progress: sessionManager.progress,
                        lineWidth: 6,
                        isPaused: sessionManager.phase == .paused,
                        isUrgent: sessionManager.isUrgent
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(completionBounce ? 1.08 : 1)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.5), value: completionBounce)
                }

                VStack(spacing: 2) {
                    Text(sessionManager.isStopwatch ? sessionManager.elapsedText : sessionManager.remainingText)
                        .font(.system(size: 28, weight: .semibold, design: timerTypographyRounded ? .rounded : .default).monospacedDigit())
                        .foregroundStyle(theme.accent)
                        .contentTransition(.numericText())
                    Text(sessionManager.isStopwatch ? "elapsed" : "remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 2) {
                Text(sessionManager.subjectName)
                    .font(.headline)
                if let topicName = sessionManager.topicName, !topicName.isEmpty {
                    Text(topicName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if sessionManager.phase == .paused {
                Label("Paused", systemImage: "pause.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notes (optional)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("What are you working on?", text: Bindable(sessionManager).draftNotes)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var extendButtons: some View {
        HStack(spacing: 8) {
            Button("+5 min") { sessionManager.extend(byMinutes: 5) }
            Button("+10 min") { sessionManager.extend(byMinutes: 10) }
        }
        .buttonStyle(.bordered)
    }

    private var controlButtons: some View {
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
}
