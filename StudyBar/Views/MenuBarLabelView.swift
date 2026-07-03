import SwiftUI

struct MenuBarLabelView: View {
    var sessionManager: SessionManager

    @AppStorage("selectedThemeId") private var selectedThemeId = StudyThemeId.classic
    @AppStorage("menuBarStyle") private var menuBarStyleRaw = MenuBarStyle.standard.rawValue
    @AppStorage("timerTypographyRounded") private var timerTypographyRounded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var completionBounce = false
    @State private var showCheckmark = false

    private var theme: StudyTheme {
        StudyThemeCatalog.theme(for: selectedThemeId)
    }

    private var menuBarStyle: MenuBarStyle {
        MenuBarStyle(rawValue: menuBarStyleRaw) ?? .standard
    }

    private var timerFont: Font {
        Font.system(
            size: menuBarStyle == .compact ? 11 : 12,
            weight: .medium,
            design: timerTypographyRounded ? .rounded : .default
        ).monospacedDigit()
    }

    var body: some View {
        HStack(spacing: menuBarStyle == .compact ? 2 : 4) {
            if showMenuBarIcon {
                ZStack {
                    if sessionManager.phase != .idle, !sessionManager.isStopwatch {
                        ProgressRingView(
                            progress: sessionManager.progress,
                            lineWidth: 1.5,
                            isPaused: sessionManager.phase == .paused,
                            isUrgent: sessionManager.isUrgent
                        )
                    }
                    Group {
                        if showCheckmark {
                            Image(systemName: "checkmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.green, .primary)
                        } else {
                            Image(systemName: iconName)
                                .foregroundStyle(sessionManager.phase == .running ? theme.accent : .primary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .font(.system(size: menuBarStyle == .minimal ? 10 : 11, weight: .medium))
                }
                .frame(width: 16, height: 16)
                .scaleEffect(completionBounce ? 1.2 : 1)
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.55), value: completionBounce)
            }

            if sessionManager.phase != .idle {
                Text(sessionManager.menuBarTimeText)
                    .font(timerFont)
                    .foregroundStyle(theme.accent)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9), value: sessionManager.menuBarTimeText)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: sessionManager.phase)
        .onChange(of: sessionManager.lastCompletion?.token) { _, token in
            guard token != nil else { return }
            triggerCompletionAnimation()
        }
    }

    private var showMenuBarIcon: Bool {
        if menuBarStyle == .minimal, sessionManager.phase != .idle { return false }
        return true
    }

    private var iconName: String {
        switch sessionManager.phase {
        case .idle: "book"
        case .running: sessionManager.isStopwatch ? "stopwatch" : "book.fill"
        case .paused: "pause.fill"
        }
    }

    private func triggerCompletionAnimation() {
        guard !reduceMotion else { return }
        completionBounce = true
        showCheckmark = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            completionBounce = false
            try? await Task.sleep(for: .seconds(1.8))
            showCheckmark = false
        }
    }
}
