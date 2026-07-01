import SwiftUI

struct MenuBarLabelView: View {
    var sessionManager: SessionManager

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if sessionManager.phase != .idle {
                    ProgressRingView(progress: sessionManager.progress, lineWidth: 1.5)
                }
                Image(systemName: iconName)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(width: 16, height: 16)

            if sessionManager.phase != .idle {
                Text(sessionManager.remainingText)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionManager.phase)
    }

    private var iconName: String {
        switch sessionManager.phase {
        case .idle: "book"
        case .running: "book.fill"
        case .paused: "pause.fill"
        }
    }
}
