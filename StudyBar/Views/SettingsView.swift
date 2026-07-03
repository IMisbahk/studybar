import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    var compact: Bool = true
    @AppStorage("soundOnSessionEnd") private var soundOnSessionEnd = true
    @AppStorage("floatingTimerEnabled") private var floatingTimerEnabled = true
    @AppStorage("floatingTimerOpacity") private var floatingTimerOpacity = 0.9
    @AppStorage("floatingTimerAutoHide") private var floatingTimerAutoHide = true
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var updateStatus: UpdateChecker.Status = .idle
    @State private var updateTask: Task<Void, Never>?
    @State private var pendingAsset: UpdateInstaller.ReleaseAsset?
    @State private var downloadProgress: Double = 0
    @State private var readyDmgPath: URL?
    @State private var downloadError: String?
    @State private var isInstalling = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                aboutHeader
                if !compact {
                    openDashboardButton
                }
                updatesSection
                generalSection
                floatingTimerSection
                shortcutsSection
                linksSection
                quitSection
            }
            .padding(16)
        }
        .frame(width: compact ? 300 : nil)
        .frame(maxWidth: compact ? 300 : .infinity, alignment: .leading)
        .onAppear { checkForUpdates() }
        .onDisappear { updateTask?.cancel() }
    }

    private var openDashboardButton: some View {
        Button {
            DashboardWindowController.shared.show(section: .settings)
        } label: {
            Label("Open Dashboard Window", systemImage: "macwindow")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }

    private var aboutHeader: some View {
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
    }

    private var generalSection: some View {
        settingsSection(title: "General") {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
            Toggle("Sound on Session End", isOn: $soundOnSessionEnd)
            NavigationLink {
                ManageSubjectsView()
            } label: {
                Label("Manage Subjects", systemImage: "books.vertical")
            }
        }
    }

    private var floatingTimerSection: some View {
        settingsSection(title: "Floating Timer") {
            Toggle("Show Floating Timer", isOn: $floatingTimerEnabled)
            Toggle("Auto-hide When Idle", isOn: $floatingTimerAutoHide)
                .disabled(!floatingTimerEnabled)
            VStack(alignment: .leading, spacing: 4) {
                Text("Opacity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $floatingTimerOpacity, in: 0.4...1.0, step: 0.05)
                    .disabled(!floatingTimerEnabled)
            }
        }
    }

    private var shortcutsSection: some View {
        settingsSection(title: "Keyboard Shortcuts") {
            shortcutRow("Start Last Session", "⌥⌘S")
            shortcutRow("Pause", "⌥⌘P")
            shortcutRow("Resume", "⌥⌘R")
            shortcutRow("Extend 10 Minutes", "⌥⌘E")
            shortcutRow("Open History", "⌥⌘H")
            shortcutRow("Start Session", "⌘↩")
            Text("Global shortcuts work system-wide. Open History opens the History tab next time you click the menu bar icon.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var linksSection: some View {
        settingsSection(title: "More") {
            Link(destination: URL(string: "https://github.com/IMisbahk/studybar")!) {
                Label("GitHub Repository", systemImage: "link")
            }
        }
    }

    private var quitSection: some View {
        Button("Quit StudyBar") {
            NSApplication.shared.terminate(nil)
        }
    }

    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(10)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func shortcutRow(_ title: String, _ keys: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(keys)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
        }
    }

    @ViewBuilder
    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Updates")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Group {
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
                case .updateAvailable(let latest, _):
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Version \(latest) is available")
                            .font(.subheadline)
                        if let readyDmgPath {
                            Button(isInstalling ? "Installing…" : "Restart to Update") {
                                installAndRestart()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(isInstalling)
                            Text("StudyBar will quit, install the update, and reopen automatically.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else if let downloadError {
                            Text(downloadError)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Button("Retry Download") { downloadUpdate() }
                                .controlSize(.small)
                        } else if downloadProgress > 0, downloadProgress < 1 {
                            ProgressView(value: downloadProgress)
                            Text("Downloading… \(Int(downloadProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Download Update") { downloadUpdate() }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        }
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
    }

    private func checkForUpdates() {
        updateTask?.cancel()
        updateStatus = .checking
        readyDmgPath = nil
        downloadError = nil
        downloadProgress = 0
        updateTask = Task {
            let result = await UpdateChecker.check()
            guard !Task.isCancelled else { return }
            updateStatus = result
            if case .updateAvailable(let latest, _) = result {
                pendingAsset = await UpdateInstaller.fetchLatestAsset()
                if pendingAsset?.version != latest {
                    pendingAsset = await UpdateInstaller.fetchLatestAsset()
                }
            }
        }
    }

    private func downloadUpdate() {
        guard let asset = pendingAsset else { return }
        downloadError = nil
        downloadProgress = 0.01
        updateTask?.cancel()
        updateTask = Task {
            do {
                let path = try await UpdateInstaller.download(asset: asset) { progress in
                    Task { @MainActor in
                        downloadProgress = progress
                    }
                }
                guard !Task.isCancelled else { return }
                readyDmgPath = path
                downloadProgress = 1
            } catch {
                downloadError = error.localizedDescription
                downloadProgress = 0
            }
        }
    }

    private func installAndRestart() {
        guard let path = readyDmgPath else { return }
        isInstalling = true
        downloadError = nil
        do {
            try UpdateInstaller.installAndRelaunch(dmgPath: path)
        } catch {
            downloadError = error.localizedDescription
            isInstalling = false
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
