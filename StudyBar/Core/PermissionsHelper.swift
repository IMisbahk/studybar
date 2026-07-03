import AppKit
import ApplicationServices
import UserNotifications

enum PermissionsHelper {
    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    static func requestAccessibility(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    static func notificationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func notificationsAuthorized() async -> Bool {
        await notificationStatus() == .authorized
    }

    @discardableResult
    static func requestNotificationsIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    static func migrateGlobalHotkeysDefaultIfNeeded() {
        guard UserDefaults.standard.object(forKey: "globalHotkeysEnabled") == nil else { return }
        // existing installs that already granted Accessibility keep global shortcuts
        UserDefaults.standard.set(hasAccessibility, forKey: "globalHotkeysEnabled")
    }
}
