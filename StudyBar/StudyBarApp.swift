import SwiftUI
import SwiftData

@main
struct StudyBarApp: App {
    let modelContainer: ModelContainer
    @State private var sessionManager: SessionManager

    init() {
        UserDefaults.standard.register(defaults: ["soundOnSessionEnd": true])

        let container: ModelContainer
        do {
            container = try ModelContainer(for: Subject.self, Topic.self, StudySession.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        modelContainer = container
        _sessionManager = State(initialValue: SessionManager(modelContext: container.mainContext))
        NotificationManager.shared.requestAuthorization()
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
