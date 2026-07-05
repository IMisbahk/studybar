import SwiftUI

struct FloatingTimerView: View {
    var sessionManager: SessionManager
    var isFullscreen: Bool
    var onToggleFullscreen: () -> Void

    @Environment(\.studyTheme) private var theme
    @AppStorage("timerTypographyRounded") private var timerTypographyRounded = false
    @AppStorage("floatingTimerThemedBorder") private var floatingTimerThemedBorder = true

    private var timerFont: Font {
        Font.system(
            size: isFullscreen ? 72 : 18,
            weight: .semibold,
            design: timerTypographyRounded ? .rounded : .default
        ).monospacedDigit()
    }

    var body: some View {
        Group {
            if isFullscreen {
                fullscreenBody
            } else {
                compactBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .overlay {
            if !isFullscreen {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        floatingTimerThemedBorder ? theme.accent.opacity(0.35) : Color.primary.opacity(0.1),
                        lineWidth: floatingTimerThemedBorder ? 1 : 0.5
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isFullscreen ? 0 : 12))
    }

    private var compactBody: some View {
        HStack(spacing: 10) {
            timerGlyph(size: 36, lineWidth: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionManager.subjectName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(sessionManager.menuBarTimeText)
                    .font(timerFont)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                pauseButton
                fullscreenButton
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 248, height: 72)
    }

    private var fullscreenBody: some View {
        VStack(spacing: 32) {
            Spacer()
            Text(sessionManager.subjectName)
                .font(.title.weight(.semibold))
            if let topic = sessionManager.topicName, !topic.isEmpty {
                Text(topic)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            timerGlyph(size: 280, lineWidth: 10)
                .overlay {
                    VStack(spacing: 6) {
                        Text(sessionManager.menuBarTimeText)
                            .font(timerFont)
                            .foregroundStyle(theme.accent)
                            .contentTransition(.numericText())
                        Text(sessionManager.isStopwatch ? "elapsed" : "remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                }
            if sessionManager.phase == .paused {
                Label("Paused", systemImage: "pause.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }
            HStack(spacing: 16) {
                pauseButton
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button {
                    sessionManager.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .tint(.red)
                .buttonStyle(.bordered)
                .controlSize(.large)
                fullscreenButton
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            AmbientSoundControls(compact: false)
                .frame(maxWidth: 420)
            Spacer()
        }
        .padding(40)
    }

    @ViewBuilder
    private func timerGlyph(size: CGFloat, lineWidth: CGFloat) -> some View {
        if sessionManager.isStopwatch {
            Image(systemName: "stopwatch")
                .font(.system(size: size * 0.55, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(width: size, height: size)
        } else {
            ProgressRingView(
                progress: sessionManager.progress,
                lineWidth: lineWidth,
                isPaused: sessionManager.phase == .paused,
                isUrgent: sessionManager.isUrgent
            )
            .frame(width: size, height: size)
        }
    }

    private var pauseButton: some View {
        Button {
            if sessionManager.phase == .paused {
                sessionManager.resume()
            } else {
                sessionManager.pause()
            }
        } label: {
            Image(systemName: sessionManager.phase == .paused ? "play.fill" : "pause.fill")
                .font(.system(size: isFullscreen ? 16 : 12, weight: .semibold))
                .foregroundStyle(isFullscreen ? Color.primary : theme.accent)
        }
        .buttonStyle(.plain)
        .help(sessionManager.phase == .paused ? "Resume" : "Pause")
    }

    private var fullscreenButton: some View {
        Button(action: onToggleFullscreen) {
            Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                .font(.system(size: isFullscreen ? 14 : 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help(isFullscreen ? "Exit fullscreen" : "Fullscreen")
    }
}
