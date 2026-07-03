import SwiftUI

struct DashboardSettingsView: View {
    var body: some View {
        NavigationStack {
            SettingsView(compact: false)
                .navigationTitle("Settings")
        }
    }
}
