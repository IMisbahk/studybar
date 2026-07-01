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
            Text("StudyBar")
                .font(.headline)
                .padding()
                .frame(width: 280)
        } label: {
            Image(systemName: "book.closed")
        }
        .menuBarExtraStyle(.window)
        .modelContainer(modelContainer)
    }
}
