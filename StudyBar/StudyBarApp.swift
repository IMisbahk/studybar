import SwiftUI
import SwiftData

@main
struct StudyBarApp: App {
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
            "floatingTimerAutoHide": true
        ])

        let container: ModelContainer
        do {
            container = try ModelContainer(for: Subject.self, Topic.self, StudySession.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        modelContainer = container

        let manager = SessionManager(modelContext: container.mainContext)
        _sessionManager = State(initialValue: manager)

        NotificationManager.shared.configure(sessionManager: manager)
        NotificationManager.shared.requestAuthorization()

        hotkeyManager = GlobalHotkeyManager(sessionManager: manager)
        floatingTimerController = FloatingTimerController(sessionManager: manager)
        powerEventsMonitor = PowerEventsMonitor(sessionManager: manager)

        hotkeyManager.start()
        floatingTimerController.start()
        powerEventsMonitor.start()
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
                .environment(sessionManager)
        } label: {
            MenuBarLabelView(sessionManager: sessionManager)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
    }
}
