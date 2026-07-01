import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    func fireSessionStarted(subjectName: String, topicName: String?, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Session Started"
        if let topicName, !topicName.isEmpty {
            content.body = "Studying \(subjectName) — \(topicName) for \(minutes) minutes"
        } else {
            content.body = "Studying \(subjectName) for \(minutes) minutes"
        }
        content.sound = .default
        fire(content)
    }

    func fireSessionCompleted(subjectName: String, minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete"
        content.body = "\(subjectName), \(minutes) min"
        content.sound = .default
        fire(content)
    }

    private func fire(_ content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
