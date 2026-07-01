import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @AppStorage("soundOnSessionEnd") private var soundOnSessionEnd = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                AppLogoView(size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("StudyBar")
                        .font(.title3.bold())
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Group {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Toggle("Sound on Session End", isOn: $soundOnSessionEnd)
            }

            NavigationLink {
                ManageSubjectsView()
            } label: {
                Label("Manage Subjects", systemImage: "books.vertical")
            }

            Link(destination: URL(string: "https://github.com/IMisbahk/studybar")!) {
                Label("GitHub Repository", systemImage: "link")
            }

            Divider()

            Button("Quit StudyBar") {
                NSApplication.shared.terminate(nil)
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
            print("Failed to toggle launch at login: \(error)")
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
