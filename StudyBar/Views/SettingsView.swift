import SwiftUI
import ServiceManagement
import AppKit
import SwiftData

struct SettingsView: View {
    var compact: Bool = true
    @Environment(\.modelContext) private var modelContext
    @AppStorage("soundOnSessionEnd") private var soundOnSessionEnd = true
    @AppStorage("floatingTimerEnabled") private var floatingTimerEnabled = true
    @AppStorage("floatingTimerOpacity") private var floatingTimerOpacity = 0.9
    @AppStorage("floatingTimerAutoHide") private var floatingTimerAutoHide = true
    @AppStorage("studyRemindersEnabled") private var studyRemindersEnabled = true
    @AppStorage("peakHourRemindersEnabled") private var peakHourRemindersEnabled = true
    @AppStorage("inactivityRemindersEnabled") private var inactivityRemindersEnabled = true
    @AppStorage("inactivityReminderDays") private var inactivityReminderDays = 2
    @AppStorage("weeklyRecapRemindersEnabled") private var weeklyRecapRemindersEnabled = true
    @AppStorage("pauseNudgeEnabled") private var pauseNudgeEnabled = true
    @AppStorage("dailyGoalMinutes") private var dailyGoalMinutes = 45
    @AppStorage("weeklyGoalMinutes") private var weeklyGoalMinutes = 300
    @AppStorage("autoUpdateEnabled") private var autoUpdateEnabled = true
    @AppStorage("autoUpdateInstallEnabled") private var autoUpdateInstallEnabled = true
    @AppStorage("showOnboardingNow") private var showOnboardingNow = false
    @AppStorage("globalHotkeysEnabled") private var globalHotkeysEnabled = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var notificationsAuthorized = false
    @State private var accessibilityGranted = PermissionsHelper.hasAccessibility
    @State private var updateStatus: UpdateChecker.Status = .idle
    @State private var backupMessage: String?
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
                goalsSection
                themesSection
                remindersSection
                dataSection
                ambientSoundSection
                floatingTimerSection
                shortcutsSection
                quitSection
            }
            .padding(16)
        }
        .frame(width: compact ? PopoverLayout.paneWidth : nil)
        .frame(maxWidth: compact ? PopoverLayout.paneWidth : .infinity, alignment: .leading)
        .frame(maxHeight: compact ? .infinity : nil, alignment: .top)
        .onAppear {
            checkForUpdates()
            StudyReminderScheduler.shared.reschedule(in: modelContext)
            refreshPermissionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshPermissionStatus()
            GlobalHotkeyManager.shared?.refreshGlobalMonitor()
        }
        .onChange(of: peakHourRemindersEnabled) { _, _ in StudyReminderScheduler.shared.reschedule(in: modelContext) }
        .onChange(of: inactivityRemindersEnabled) { _, _ in StudyReminderScheduler.shared.reschedule(in: modelContext) }
        .onChange(of: inactivityReminderDays) { _, _ in StudyReminderScheduler.shared.reschedule(in: modelContext) }
        .onChange(of: weeklyRecapRemindersEnabled) { _, _ in StudyReminderScheduler.shared.reschedule(in: modelContext) }
        .onChange(of: autoUpdateEnabled) { _, _ in UpdateAutoMonitor.shared.restartIfNeeded() }
        .onChange(of: autoUpdateInstallEnabled) { _, _ in UpdateAutoMonitor.shared.restartIfNeeded() }
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
            Button {
                showOnboardingNow = true
                NotificationCenter.default.post(name: .studyBarShowOnboarding, object: nil)
            } label: {
                Label("Show Welcome Tour", systemImage: "hand.wave.fill")
            }
        }
    }

    private var themesSection: some View {
        Group {
            if compact {
                NavigationLink {
                    ThemesSettingsView(compact: true)
                } label: {
                    Label("Themes & Appearance", systemImage: "paintpalette.fill")
                }
            } else {
                settingsSection(title: "Themes") {
                    ThemesSettingsView(compact: true)
                }
            }
        }
    }

    private var goalsSection: some View {
        settingsSection(title: "Study Goals") {
            Stepper(value: $dailyGoalMinutes, in: 0...480, step: 15) {
                Text(dailyGoalMinutes == 0 ? "Daily goal: off" : "Daily goal: \(dailyGoalMinutes) min")
                    .font(.subheadline)
            }
            Stepper(value: $weeklyGoalMinutes, in: 0...3000, step: 30) {
                Text(weeklyGoalMinutes == 0 ? "Weekly goal: off" : "Weekly goal: \(weeklyGoalMinutes) min")
                    .font(.subheadline)
            }
            Text("Goals appear on the timer screen and dashboard overview.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var remindersSection: some View {
        settingsSection(title: "Study Reminders") {
            Toggle("Study Reminders", isOn: $studyRemindersEnabled)
                .onChange(of: studyRemindersEnabled) { _, enabled in
                    if enabled {
                        Task {
                            _ = await PermissionsHelper.requestNotificationsIfNeeded()
                            await MainActor.run { refreshPermissionStatus() }
                        }
                    }
                    StudyReminderScheduler.shared.reschedule(in: modelContext)
                }
            if studyRemindersEnabled && !notificationsAuthorized {
                Text("Tap Allow on the macOS prompt to receive reminders. No System Settings needed unless you previously denied.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Request Notification Access") {
                    Task {
                        _ = await PermissionsHelper.requestNotificationsIfNeeded()
                        await MainActor.run { refreshPermissionStatus() }
                    }
                }
                .controlSize(.small)
            }
            Toggle("Peak Focus Time", isOn: $peakHourRemindersEnabled)
                .disabled(!studyRemindersEnabled)
            Toggle("Inactivity Nudges", isOn: $inactivityRemindersEnabled)
                .disabled(!studyRemindersEnabled)
            Toggle("Sunday Week Recap", isOn: $weeklyRecapRemindersEnabled)
                .disabled(!studyRemindersEnabled)
            Toggle("Pause Too Long Nudge", isOn: $pauseNudgeEnabled)
                .onChange(of: pauseNudgeEnabled) { _, enabled in
                    if enabled {
                        Task {
                            _ = await PermissionsHelper.requestNotificationsIfNeeded()
                            await MainActor.run { refreshPermissionStatus() }
                        }
                    }
                }
            if studyRemindersEnabled && inactivityRemindersEnabled {
                Stepper("Nudge after \(inactivityReminderDays) day\(inactivityReminderDays == 1 ? "" : "s")", value: $inactivityReminderDays, in: 1...14)
                    .font(.subheadline)
            }
            Text("Peak time uses your most productive hour from session history. Inactivity reminders fire if you haven't studied recently.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var ambientSoundSection: some View {
        settingsSection(title: "Ambient Sound") {
            AmbientSoundControls(compact: compact)
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
            Toggle("Global shortcuts (⌥⌘ from any app)", isOn: $globalHotkeysEnabled)
                .onChange(of: globalHotkeysEnabled) { _, enabled in
                    if enabled {
                        accessibilityGranted = PermissionsHelper.requestAccessibility(prompt: true)
                    }
                    GlobalHotkeyManager.shared?.refreshGlobalMonitor()
                }
            if globalHotkeysEnabled && !accessibilityGranted {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Turn on StudyBar in Accessibility to use shortcuts outside the menu bar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("Open Accessibility Settings") {
                    PermissionsHelper.openAccessibilitySettings()
                }
                .controlSize(.small)
            } else if globalHotkeysEnabled {
                Label("Global shortcuts active", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("Shortcuts still work while the menu bar popover is open.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            shortcutRow("Start Last Session", "⌥⌘S")
            shortcutRow("Pause", "⌥⌘P")
            shortcutRow("Resume", "⌥⌘R")
            shortcutRow("Extend 10 Minutes", "⌥⌘E")
            shortcutRow("Open Timeline", "⌥⌘H")
            shortcutRow("Start Session", "⌘↩")
        }
    }

    private func refreshPermissionStatus() {
        accessibilityGranted = PermissionsHelper.hasAccessibility
        Task {
            notificationsAuthorized = await PermissionsHelper.notificationsAuthorized()
        }
    }

    private var quitSection: some View {
        Button("Quit StudyBar") {
            NSApplication.shared.terminate(nil)
        }
    }

    private var dataSection: some View {
        settingsSection(title: "Backup & Restore") {
            Button("Export Backup to Downloads") {
                do {
                    let url = try BackupService.exportBackup()
                    backupMessage = "Saved \(url.lastPathComponent)"
                } catch {
                    backupMessage = error.localizedDescription
                }
            }
            Button("Restore from Backup…") {
                BackupService.pickAndRestore()
            }
            if let backupMessage {
                Text(backupMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Backup includes all sessions, subjects, XP, and achievements.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
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
                            if !updateLogPath.isEmpty {
                                Text("Log: \(updateLogPath)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .textSelection(.enabled)
                            }
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

            settingsSection(title: "Automatic Updates") {
                Toggle("Check every 6 hours", isOn: $autoUpdateEnabled)
                Toggle("Install when idle", isOn: $autoUpdateInstallEnabled)
                    .disabled(!autoUpdateEnabled)
                Text("Downloads from GitHub releases. Installs only when no session is running.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Link(destination: URL(string: "https://rzp.io/rzp/studybar")!) {
                    Label("Support StudyBar", systemImage: "heart.fill")
                }
                Link(destination: URL(string: "https://github.com/IMisbahk/studybar")!) {
                    Label("GitHub Repository", systemImage: "link")
                }
            }
            .padding(10)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var updateLogPath: String {
        (try? UpdateInstaller.installLogURL().path) ?? ""
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
