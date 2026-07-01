import SwiftUI

@main
struct StudyBarApp: App {
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
    }
}
