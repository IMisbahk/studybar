import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool
    var onFinish: () -> Void = {}

    @State private var step = 0
    @State private var subjectName = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            TabView(selection: $step) {
                welcomeStep.tag(0)
                subjectStep.tag(1)
                notificationsStep.tag(2)
                goalsStep.tag(3)
                finishStep.tag(4)
            }
            .tabViewStyle(.automatic)
            .labelsHidden()
            .frame(height: 280)
            Divider()
            footer
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

    private var notificationsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stay on track")
                .font(.title3.bold())
            Text("Allow notifications for session alerts, study reminders, and weekly recaps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Enable Notifications") {
                NotificationManager.shared.requestAuthorization()
            }
            .buttonStyle(.borderedProminent)
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
                Button("Next") { advance() }
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
