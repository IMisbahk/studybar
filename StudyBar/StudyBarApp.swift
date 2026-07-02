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
        }
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
