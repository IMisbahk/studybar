import SwiftUI
import AppKit

struct MenuBarLabelView: View {
    var sessionManager: SessionManager

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if sessionManager.phase != .idle {
                    ProgressRingView(progress: sessionManager.progress, lineWidth: 1.5)
                }
                if sessionManager.phase == .idle, let icon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 14, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                } else {
                    Image(systemName: activeSymbol)
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .frame(width: 16, height: 16)

            if sessionManager.phase != .idle {
                Text(sessionManager.remainingText)
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionManager.phase)
    }

    private var activeSymbol: String {
        sessionManager.phase == .paused ? "pause.fill" : "book.closed.fill"
    }
}
