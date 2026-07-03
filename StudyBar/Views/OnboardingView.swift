import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool
    var onFinish: () -> Void = {}

    @AppStorage("globalHotkeysEnabled") private var globalHotkeysEnabled = false
    @State private var step = 0
    @State private var subjectName = ""
    @State private var notificationsGranted = false
    @State private var shortcutsGranted = PermissionsHelper.hasAccessibility

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            TabView(selection: $step) {
                welcomeStep.tag(0)
                subjectStep.tag(1)
                permissionsStep.tag(2)
                goalsStep.tag(3)
                finishStep.tag(4)
            }
            .tabViewStyle(.automatic)
            .labelsHidden()
            .frame(height: 300)
            Divider()
            footer
        }
        .task {
            notificationsGranted = await PermissionsHelper.notificationsAuthorized()
            shortcutsGranted = PermissionsHelper.hasAccessibility
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            shortcutsGranted = PermissionsHelper.hasAccessibility
            if shortcutsGranted && globalHotkeysEnabled {
                GlobalHotkeyManager.shared?.refreshGlobalMonitor()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            AppLogoView(size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome to StudyBar")
                    .font(.headline)
                Text("Step \(step + 1) of 5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your menu bar study timer")
                .font(.title3.bold())
            Text("Start focused sessions, track your progress, and build habits — all local, no account needed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("StudyBar lives in the menu bar (book icon). There is no Dock icon.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subjectStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add your first subject")
                .font(.title3.bold())
            Text("What are you studying? You can add more later.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField("e.g. Physics, Maths", text: $subjectName)
                .textFieldStyle(.roundedBorder)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Optional permissions")
                .font(.title3.bold())
            Text("Everything works without these. Enable only what you want — you can change them later in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications", systemImage: "bell.badge")
                    .font(.subheadline.weight(.semibold))
                Text("One-tap Allow on the macOS dialog. No System Settings unless you previously denied.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if notificationsGranted {
                    Label("Enabled", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Button("Enable Notifications") {
                        Task {
                            notificationsGranted = await PermissionsHelper.requestNotificationsIfNeeded()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Global keyboard shortcuts", systemImage: "keyboard")
                    .font(.subheadline.weight(.semibold))
                Text("⌥⌘S/P/R/E from any app. Skip this to use shortcuts only while the menu bar popover is open.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if shortcutsGranted && globalHotkeysEnabled {
                    Label("Enabled", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Button("Enable Global Shortcuts") {
                        globalHotkeysEnabled = true
                        shortcutsGranted = PermissionsHelper.requestAccessibility(prompt: true)
                        GlobalHotkeyManager.shared?.refreshGlobalMonitor()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set a daily goal")
                .font(.title3.bold())
            Text("Optional — you can change this anytime in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Stepper(value: Binding(
                get: { max(0, UserDefaults.standard.integer(forKey: "dailyGoalMinutes")) },
                set: { UserDefaults.standard.set($0, forKey: "dailyGoalMinutes") }
            ), in: 0...480, step: 15) {
                let mins = UserDefaults.standard.integer(forKey: "dailyGoalMinutes")
                Text(mins == 0 ? "No daily goal" : "\(mins) minutes / day")
                    .font(.subheadline)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var finishStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You're all set")
                .font(.title3.bold())
            Text("Open the dashboard for analytics and insights. Pick a color theme in Settings → Themes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Dashboard") {
                DashboardWindowController.shared.show()
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            if step > 0 {
                Button("Back") { step -= 1 }
            }
            Spacer()
            if step < 4 {
                Button(step == 2 ? "Skip for Now" : "Next") { advance() }
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Get Started") { complete() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
    }

    private func advance() {
        if step == 1 { addSubjectIfNeeded() }
        step += 1
    }

    private func complete() {
        addSubjectIfNeeded()
        if UserDefaults.standard.integer(forKey: "dailyGoalMinutes") == 0 {
            UserDefaults.standard.set(45, forKey: "dailyGoalMinutes")
        }
        hasCompletedOnboarding = true
        StudyReminderScheduler.shared.reschedule(in: modelContext)
        onFinish()
    }

    private func addSubjectIfNeeded() {
        let name = subjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let descriptor = FetchDescriptor<Subject>(predicate: #Predicate { $0.name == name })
        if (try? modelContext.fetch(descriptor).first) != nil { return }
        modelContext.insert(Subject(name: name))
        try? modelContext.save()
    }
}
