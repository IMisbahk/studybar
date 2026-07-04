import AppKit
import SwiftUI

@MainActor
final class FloatingTimerController {
    static weak var shared: FloatingTimerController?

    private weak var sessionManager: SessionManager?
    private var panel: NSPanel?
    private var panelIsVisible = false
    private var menuPopoverIsOpen = false
    private var isFullscreen = false
    private var compactFrame: NSRect?
    private var observers: [NSObjectProtocol] = []

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        Self.shared = self
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
        observers.append(center.addObserver(
            forName: .studyBarThemeChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshPanelContent()
        })
    }

    func toggleFullscreen() {
        guard let panel, panelIsVisible else { return }
        isFullscreen.toggle()
        if isFullscreen {
            compactFrame = panel.frame
            let target = (panel.screen ?? NSScreen.main)?.visibleFrame
                ?? NSRect(x: 0, y: 0, width: 800, height: 600)
            panel.setFrame(target, display: true)
            panel.isMovableByWindowBackground = false
        } else if let compactFrame {
            panel.setFrame(compactFrame, display: true)
            panel.isMovableByWindowBackground = true
        }
        refreshPanelContent()
    }

    private func refreshPanelContent() {
        guard let sessionManager, let panel else { return }
        let content = StudyThemeProvider { [self] in
            FloatingTimerView(
                sessionManager: sessionManager,
                isFullscreen: isFullscreen,
                onToggleFullscreen: { [weak self] in self?.toggleFullscreen() }
            )
        }
        let hosting = NSHostingView(rootView: content)
        hosting.frame = NSRect(origin: .zero, size: panel.frame.size)
        panel.contentView = hosting
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func syncVisibility() {
        guard let sessionManager else { return }

        if menuPopoverIsOpen {
            hidePanel()
            return
        }

        let enabled = UserDefaults.standard.object(forKey: "floatingTimerEnabled") as? Bool ?? true

        guard enabled, sessionManager.phase != .idle else {
            if isFullscreen { isFullscreen = false }
            hidePanel()
            return
        }

        showPanel(sessionManager: sessionManager)
    }

    private func showPanel(sessionManager: SessionManager) {
        let opacity = UserDefaults.standard.object(forKey: "floatingTimerOpacity") as? Double ?? 0.9
        let compactSize = NSSize(width: 228, height: 72)

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 200, y: 200, width: compactSize.width, height: compactSize.height),
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
            self.panel = panel
            refreshPanelContent()
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
