import AppKit
import SwiftUI

final class FloatingTimerController {
    private weak var sessionManager: SessionManager?
    private var panel: NSPanel?
    private var panelIsVisible = false
    private var menuPopoverIsOpen = false
    private var observers: [NSObjectProtocol] = []

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func start() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: .studyBarSessionPhaseChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncVisibility()
        })
        observers.append(center.addObserver(
            forName: .studyBarMenuPopoverVisible,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.menuPopoverIsOpen = (note.object as? Bool) ?? false
            self?.syncVisibility()
        })
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func syncVisibility() {
        guard let sessionManager else { return }

        // never cover the menu bar popover
        if menuPopoverIsOpen {
            hidePanel()
            return
        }

        let enabled = UserDefaults.standard.object(forKey: "floatingTimerEnabled") as? Bool ?? true

        // only show during an active session — never when idle (empty timer blocked clicks)
        guard enabled, sessionManager.phase != .idle else {
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
                styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .normal
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.hidesOnDeactivate = false
            panel.contentView = hosting
            self.panel = panel
        }

        panel?.alphaValue = opacity
        if !panelIsVisible {
            panel?.orderFront(nil)
            panelIsVisible = true
        }
    }

    private func hidePanel() {
        guard panelIsVisible else { return }
        panel?.orderOut(nil)
        panelIsVisible = false
    }
}
