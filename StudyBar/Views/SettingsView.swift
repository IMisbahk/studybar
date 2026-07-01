import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("soundOnSessionEnd") private var soundOnSessionEnd = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.title3.bold())

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }

            Toggle("Sound on Session End", isOn: $soundOnSessionEnd)

            NavigationLink("Manage Subjects…") {
                ManageSubjectsView()
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // SMAppService registration can fail if the app isn't in /Applications - revert the toggle
            print("Failed to toggle launch at login: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
