import SwiftUI
import SwiftData

@main
struct StudyBarApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Subject.self, Topic.self, StudySession.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverRootView()
        } label: {
            Image(systemName: "book.closed")
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
    }
}
