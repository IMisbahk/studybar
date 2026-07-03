import SwiftUI
import SwiftData

@main
struct StudyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let modelContainer: ModelContainer
    @State private var sessionManager: SessionManager
    private let hotkeyManager: GlobalHotkeyManager
    private let floatingTimerController: FloatingTimerController
    private let powerEventsMonitor: PowerEventsMonitor

    init() {
        UserDefaults.standard.register(defaults: [
            "soundOnSessionEnd": true,
            "floatingTimerEnabled": true,
            "floatingTimerOpacity": 0.9,
            "floatingTimerAutoHide": true,
            "studyRemindersEnabled": true,
            "peakHourRemindersEnabled": true,
            "inactivityRemindersEnabled": true,
            "inactivityReminderDays": 2,
            "weeklyRecapRemindersEnabled": true,
            "pauseNudgeEnabled": true,
            "dailyGoalMinutes": 45,
            "weeklyGoalMinutes": 300,
            "autoUpdateEnabled": true,
            "autoUpdateInstallEnabled": true,
            "hasCompletedOnboarding": false,
            "selectedThemeId": StudyThemeId.classic,
            "menuBarStyle": MenuBarStyle.standard.rawValue,
            "timerTypographyRounded": false,
            "floatingTimerThemedBorder": true
        ])

        let container: ModelContainer
        do {
            container = try StudyDataStore.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        modelContainer = container

        let manager = SessionManager(modelContext: container.mainContext)
        _sessionManager = State(initialValue: manager)

        GamificationEngine.backfillIfNeeded(in: container.mainContext)

        NotificationManager.shared.configure(sessionManager: manager)
        DashboardWindowController.shared.configure(sessionManager: manager, modelContainer: container)

        let hotkeys = GlobalHotkeyManager(sessionManager: manager)
        let floating = FloatingTimerController(sessionManager: manager)
        let power = PowerEventsMonitor(sessionManager: manager)

        hotkeyManager = hotkeys
        floatingTimerController = floating
        powerEventsMonitor = power

        // defer so MenuBarExtra can register before any NSPanel/orderFront runs
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationManager.shared.requestAuthorization()
            hotkeys.start()
            floating.start()
            power.start()
            StudyReminderScheduler.shared.reschedule(in: container.mainContext)
            UpdateAutoMonitor.shared.configure(sessionManager: manager)
            UpdateAutoMonitor.shared.start()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            StudyThemeProvider {
                PopoverRootView()
                    .environment(sessionManager)
            }
        } label: {
            StudyThemeProvider {
                MenuBarLabelView(sessionManager: sessionManager)
            }
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
    }
}
