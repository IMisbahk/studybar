import SwiftUI

struct FloatingTimerView: View {
    var sessionManager: SessionManager

    @Environment(\.studyTheme) private var theme
    @AppStorage("timerTypographyRounded") private var timerTypographyRounded = false
    @AppStorage("floatingTimerThemedBorder") private var floatingTimerThemedBorder = true

    private var timerFont: Font {
        Font.system(size: 18, weight: .semibold, design: timerTypographyRounded ? .rounded : .default).monospacedDigit()
    }

    var body: some View {
        HStack(spacing: 10) {
            if sessionManager.isStopwatch {
                Image(systemName: "stopwatch")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 36, height: 36)
            } else {
                ProgressRingView(
                    progress: sessionManager.progress,
                    lineWidth: 3,
                    isPaused: sessionManager.phase == .paused,
                    isUrgent: sessionManager.isUrgent
                )
                .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sessionManager.subjectName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(sessionManager.menuBarTimeText)
                    .font(timerFont)
            }

            Spacer(minLength: 0)

            Button {
                if sessionManager.phase == .paused {
                    sessionManager.resume()
                } else {
                    sessionManager.pause()
                }
            } label: {
                Image(systemName: sessionManager.phase == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
            .help(sessionManager.phase == .paused ? "Resume" : "Pause")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(floatingTimerThemedBorder ? theme.accent.opacity(0.35) : Color.primary.opacity(0.1), lineWidth: floatingTimerThemedBorder ? 1 : 0.5)
        )
        .frame(width: 200, height: 72)
    }
}
