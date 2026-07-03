import Foundation
import UserNotifications
import SwiftData

enum StudyReminderId {
    static let peakHour = "studybar.reminder.peakHour"
    static let inactivity = "studybar.reminder.inactivity"
}

@MainActor
final class StudyReminderScheduler {
    static let shared = StudyReminderScheduler()

    private init() {}

    func reschedule(in context: ModelContext) {
        let sessions = (try? context.fetch(FetchDescriptor<StudySession>())) ?? []
        reschedule(sessions: sessions)
    }

    func reschedule(sessions: [StudySession]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            StudyReminderId.peakHour,
            StudyReminderId.inactivity
        ])

        guard UserDefaults.standard.bool(forKey: "studyRemindersEnabled") else { return }

        if UserDefaults.standard.bool(forKey: "peakHourRemindersEnabled") {
            schedulePeakHourReminder(sessions: sessions, center: center)
        }
        if UserDefaults.standard.bool(forKey: "inactivityRemindersEnabled") {
            scheduleInactivityReminder(sessions: sessions, center: center)
        }
    }

    private func schedulePeakHourReminder(sessions: [StudySession], center: UNUserNotificationCenter) {
        guard sessions.count >= 3 else { return }
        let hour = AnalyticsEngine.overview(from: sessions).mostProductiveHour

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Good time to study"
        content.body = "You usually focus well around \(formatHour(hour)). Start a session when you're ready."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: StudyReminderId.peakHour, content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleInactivityReminder(sessions: [StudySession], center: UNUserNotificationCenter) {
        guard let lastEnded = sessions.map(\.endedAt).max() else { return }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastEnded), to: calendar.startOfDay(for: Date())).day ?? 0
        let threshold = UserDefaults.standard.integer(forKey: "inactivityReminderDays")
        let inactiveAfter = max(1, threshold == 0 ? 2 : threshold)

        let content = UNMutableNotificationContent()
        content.sound = .default

        if daysSince >= inactiveAfter {
            content.title = "Time to study?"
            content.body = "You haven't logged a session in \(daysSince) day\(daysSince == 1 ? "" : "s"). Even 25 minutes counts."
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
            center.add(UNNotificationRequest(identifier: StudyReminderId.inactivity, content: content, trigger: trigger))
            return
        }

        guard let nudgeDate = calendar.date(byAdding: .day, value: inactiveAfter, to: lastEnded),
              nudgeDate > Date() else { return }

        content.title = "Keep your streak alive"
        content.body = "Your last session was \(daysSince == 0 ? "today" : "\(daysSince) day\(daysSince == 1 ? "" : "s") ago"). Plan one before the gap gets too long."

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nudgeDate)
        if components.hour == nil { components.hour = 18; components.minute = 0 }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: StudyReminderId.inactivity, content: content, trigger: trigger))
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h < 12 { return "\(h) AM" }
        if h == 12 { return "12 PM" }
        return "\(h - 12) PM"
    }
}
