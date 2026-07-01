import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @AppStorage("soundOnSessionEnd") private var soundOnSessionEnd = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var updateStatus: UpdateChecker.Status = .idle
    @State private var updateTask: Task<Void, Never>?

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

            updatesSection

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
        .onAppear { checkForUpdates() }
        .onDisappear { updateTask?.cancel() }
    }

    @ViewBuilder
    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Updates")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch updateStatus {
            case .idle, .checking:
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Checking for updates…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            case .upToDate:
                Label("You're up to date", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            case .updateAvailable(let latest, let url):
                VStack(alignment: .leading, spacing: 6) {
                    Text("Version \(latest) is available")
                        .font(.subheadline)
                    Button("Download Update") {
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            case .failed:
                HStack {
                    Text("Couldn't check for updates")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Retry") { checkForUpdates() }
                        .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
    }

    private func checkForUpdates() {
        updateTask?.cancel()
        updateStatus = .checking
        updateTask = Task {
            let result = await UpdateChecker.check()
            guard !Task.isCancelled else { return }
            updateStatus = result
        }
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
