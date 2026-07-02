import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if DashboardWindowController.shared.isVisible {
            DashboardWindowController.shared.close()
            return .terminateCancel
        }
        return .terminateNow
    }
}
