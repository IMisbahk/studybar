import AppKit
import SwiftData
import SwiftUI

@MainActor
final class DashboardWindowController {
    static let shared = DashboardWindowController()

    private var window: NSWindow?
    private weak var sessionManager: SessionManager?
    private var modelContainer: ModelContainer?

    var isVisible: Bool { window?.isVisible == true }

    private init() {}

    func configure(sessionManager: SessionManager, modelContainer: ModelContainer) {
        self.sessionManager = sessionManager
        self.modelContainer = modelContainer
    }

    func show(section: DashboardSection = .overview) {
        guard let sessionManager, let modelContainer else { return }

        if window == nil {
            let root = DashboardView(initialSection: section)
                .environment(sessionManager)
                .modelContainer(modelContainer)
            let hosting = NSHostingView(rootView: root)
            hosting.frame = NSRect(x: 0, y: 0, width: 920, height: 640)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 920, height: 640),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "StudyBar"
            window.contentView = hosting
            window.minSize = NSSize(width: 720, height: 480)
            window.center()
            window.isReleasedWhenClosed = false
            self.window = window
        }

        NotificationCenter.default.post(name: .studyBarOpenDashboard, object: section)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
    }
}
