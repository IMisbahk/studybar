import AppKit
import SwiftUI

final class FloatingTimerController {
    private weak var sessionManager: SessionManager?
    private var panel: NSPanel?
    private var syncTimer: Timer?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func start() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.syncVisibility()
        }
    }

    private func syncVisibility() {
        guard let sessionManager else { return }
        let enabled = UserDefaults.standard.object(forKey: "floatingTimerEnabled") as? Bool ?? true
        let autoHide = UserDefaults.standard.object(forKey: "floatingTimerAutoHide") as? Bool ?? true

        if !enabled || (autoHide && sessionManager.phase == .idle) {
            hidePanel()
            return
        }

        showPanel(sessionManager: sessionManager)
    }

    private func showPanel(sessionManager: SessionManager) {
        let opacity = UserDefaults.standard.object(forKey: "floatingTimerOpacity") as? Double ?? 0.9

        if panel == nil {
            let content = FloatingTimerView(sessionManager: sessionManager)
            let hosting = NSHostingView(rootView: content)
            hosting.frame.size = NSSize(width: 200, height: 72)

            let panel = NSPanel(
                contentRect: NSRect(x: 200, y: 200, width: 200, height: 72),
                styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.contentView = hosting
            self.panel = panel
        }

        panel?.alphaValue = opacity
        if panel?.isVisible != true {
            panel?.orderFrontRegardless()
        }
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }
}
