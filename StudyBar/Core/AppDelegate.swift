import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidBecomeActive(_ notification: Notification) {
        GlobalHotkeyManager.shared?.refreshGlobalMonitor()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if UpdateInstaller.isRelaunchPending {
            return .terminateNow
        }
        if DashboardWindowController.shared.isVisible {
            DashboardWindowController.shared.close()
            return .terminateCancel
        }
        return .terminateNow
    }
}
