import Foundation
import UserNotifications

enum NotificationActionId {
    static let pause = "PAUSE_SESSION"
    static let resume = "RESUME_SESSION"
    static let extend = "EXTEND_SESSION"
    static let stop = "STOP_SESSION"
    static let showInFinder = "SHOW_IN_FINDER"
}

enum NotificationCategoryId {
    static let active = "SESSION_ACTIVE"
    static let complete = "SESSION_COMPLETE"
    static let export = "EXPORT_SAVED"
}

enum NotificationUserInfoKey {
    static let exportPath = "exportPath"
}

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private weak var sessionManager: SessionManager?

    private override init() {
        super.init()
    }

    func configure(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    private func registerCategories() {
        let pause = UNNotificationAction(identifier: NotificationActionId.pause, title: "Pause", options: [])
        let resume = UNNotificationAction(identifier: NotificationActionId.resume, title: "Resume", options: [])
        let extend = UNNotificationAction(identifier: NotificationActionId.extend, title: "+10 min", options: [])
        let stop = UNNotificationAction(identifier: NotificationActionId.stop, title: "Stop", options: [.destructive])

        let activeCategory = UNNotificationCategory(
            identifier: NotificationCategoryId.active,
            actions: [pause, extend, stop],
            intentIdentifiers: [],
            options: []
        )

        let completeCategory = UNNotificationCategory(
            identifier: NotificationCategoryId.complete,
            actions: [extend],
            intentIdentifiers: [],
            options: []
        )

        let showInFinder = UNNotificationAction(
            identifier: NotificationActionId.showInFinder,
            title: "Show in Finder",
            options: []
        )
        let exportCategory = UNNotificationCategory(
            identifier: NotificationCategoryId.export,
            actions: [showInFinder],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([activeCategory, completeCategory, exportCategory])
    }

    func fireSessionStarted(subjectName: String, topicName: String?, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Study session started"
        if let topicName, !topicName.isEmpty {
            content.subtitle = "\(subjectName) · \(topicName)"
        } else {
            content.subtitle = subjectName
        }
        content.body = "\(minutes) minutes on the clock. You've got this."
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryId.active
        fire(content)
    }

    func fireStopwatchStarted(subjectName: String, topicName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Stopwatch started"
        if let topicName, !topicName.isEmpty {
            content.subtitle = "\(subjectName) · \(topicName)"
        } else {
            content.subtitle = subjectName
        }
        content.body = "Study for as long as you need. Stop when you're done."
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryId.active
        fire(content)
    }

    func fireSessionCompleted(subjectName: String, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Session complete"
        content.subtitle = subjectName
        content.body = "Nice work — \(minutes) minutes logged."
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryId.complete
        fire(content)
    }

    func fireExportSaved(fileURL: URL) {
        let content = UNMutableNotificationContent()
        content.title = "Export saved"
        content.subtitle = fileURL.lastPathComponent
        content.body = "Saved to your Downloads folder. Tap to show in Finder."
        content.sound = .default
        content.categoryIdentifier = NotificationCategoryId.export
        content.userInfo = [NotificationUserInfoKey.exportPath: fileURL.path]
        fire(content)
    }

    private func fire(_ content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            if response.notification.request.content.categoryIdentifier == NotificationCategoryId.export {
                revealExportIfNeeded(from: response)
                return
            }
            handleAction(response.actionIdentifier)
        }
    }

    @MainActor
    private func revealExportIfNeeded(from response: UNNotificationResponse) {
        let showFinder = response.actionIdentifier == NotificationActionId.showInFinder
            || response.actionIdentifier == UNNotificationDefaultActionIdentifier
        guard showFinder,
              let path = response.notification.request.content.userInfo[NotificationUserInfoKey.exportPath] as? String else { return }
        ExportService.revealInFinder(URL(fileURLWithPath: path))
    }

    @MainActor
    private func handleAction(_ actionId: String) {
        guard let sessionManager else { return }
        switch actionId {
        case NotificationActionId.pause:
            sessionManager.pause()
        case NotificationActionId.resume:
            sessionManager.resume()
        case NotificationActionId.extend:
            sessionManager.extend(byMinutes: 10)
        case NotificationActionId.stop:
            sessionManager.stop()
        default:
            break
        }
    }
}
