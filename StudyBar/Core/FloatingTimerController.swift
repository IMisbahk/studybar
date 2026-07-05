import AppKit
import SwiftUI

@MainActor
final class FloatingTimerController {
    static weak var shared: FloatingTimerController?

    private static let compactSize = NSSize(width: 248, height: 72)

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
            compactFrame = NSRect(origin: panel.frame.origin, size: Self.compactSize)
            let target = (panel.screen ?? NSScreen.main)?.visibleFrame
                ?? NSRect(x: 0, y: 0, width: 800, height: 600)
            panel.setFrame(target, display: true)
            panel.isMovableByWindowBackground = false
        } else {
            applyCompactFrame(to: panel, origin: compactFrame?.origin ?? panel.frame.origin)
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
            .environment(sessionManager)
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
            resetCompactLayout()
            hidePanel()
            return
        }

        showPanel(sessionManager: sessionManager)
    }

    private func resetCompactLayout() {
        isFullscreen = false
        compactFrame = nil
        if let panel {
            applyCompactFrame(to: panel, origin: panel.frame.origin)
            refreshPanelContent()
        }
    }

    private func applyCompactFrame(to panel: NSPanel, origin: NSPoint) {
        var frame = NSRect(origin: origin, size: Self.compactSize)
        if let screen = panel.screen ?? NSScreen.main {
            frame = frameWithinVisibleScreen(frame, on: screen.visibleFrame)
        }
        panel.setFrame(frame, display: true)
        compactFrame = frame
    }

    private func frameWithinVisibleScreen(_ frame: NSRect, on visible: NSRect) -> NSRect {
        var adjusted = frame
        if adjusted.maxX > visible.maxX {
            adjusted.origin.x = visible.maxX - adjusted.width
        }
        if adjusted.minX < visible.minX {
            adjusted.origin.x = visible.minX
        }
        if adjusted.maxY > visible.maxY {
            adjusted.origin.y = visible.maxY - adjusted.height
        }
        if adjusted.minY < visible.minY {
            adjusted.origin.y = visible.minY
        }
        return adjusted
    }

    private func showPanel(sessionManager: SessionManager) {
        let opacity = UserDefaults.standard.object(forKey: "floatingTimerOpacity") as? Double ?? 0.9

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 200, y: 200, width: Self.compactSize.width, height: Self.compactSize.height),
                styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.hidesOnDeactivate = false
            self.panel = panel
            refreshPanelContent()
        }

        if let panel, !isFullscreen, panel.frame.size != Self.compactSize {
            applyCompactFrame(to: panel, origin: panel.frame.origin)
            refreshPanelContent()
        }

        panel?.alphaValue = opacity
        if !panelIsVisible {
            panelIsVisible = true
        }
        panel?.orderFrontRegardless()
    }

    private func hidePanel() {
        guard panelIsVisible else { return }
        panel?.orderOut(nil)
        panelIsVisible = false
    }
}
