import SwiftUI
import SwiftData

enum PopoverLayout {
    static let paneWidth: CGFloat = 300
    // was 508, trimmed to 418 — add half the cut back so slider clears tab bar
    static let paneHeight: CGFloat = 463
}

struct PopoverRootView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @State private var tab: PopoverTab = .timer
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showOnboardingNow") private var showOnboardingNow = false
    @State private var showOnboarding = false

    private var showingOnboarding: Bool {
        showOnboarding || showOnboardingNow
    }

    var body: some View {
        Group {
            if showingOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding) {
                    showOnboarding = false
                    showOnboardingNow = false
                }
            } else {
                VStack(spacing: 0) {
                    popoverHeader
                    content
                    Divider()
                    tabBar
                }
            }
        }
        .frame(width: showingOnboarding ? 360 : 300)
        .onAppear {
            tab = sessionManager.selectedTab
            NotificationCenter.default.post(name: .studyBarMenuPopoverVisible, object: true)
            if showOnboardingNow {
                showOnboarding = true
            } else if !hasCompletedOnboarding {
                if subjects.isEmpty {
                    showOnboarding = true
                } else {
                    hasCompletedOnboarding = true
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.post(name: .studyBarMenuPopoverVisible, object: false)
        }
        .onChange(of: sessionManager.selectedTab) { _, newTab in
            tab = newTab
        }
        .onChange(of: showOnboardingNow) { _, requested in
            if requested { showOnboarding = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .studyBarShowOnboarding)) { _ in
            showOnboarding = true
            showOnboardingNow = true
        }
        .onChange(of: hasCompletedOnboarding) { _, done in
            if done {
                showOnboarding = false
                showOnboardingNow = false
            }
        }
    }

    private var popoverHeader: some View {
        HStack {
            Text("StudyBar")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                DashboardWindowController.shared.show()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
            .help("Open Dashboard")
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch tab {
            case .timer:
                if sessionManager.phase == .idle {
                    IdleView()
                } else {
                    ActiveSessionView()
                }
            case .history:
                HistoryView()
            case .settings:
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .frame(width: PopoverLayout.paneWidth, height: PopoverLayout.paneHeight)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(PopoverTab.allCases, id: \.self) { item in
                Button {
                    tab = item
                    sessionManager.selectedTab = item
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 14))
                        Text(item.title)
                            .font(.caption2)
                    }
                    .foregroundStyle(tab == item ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 36)
                    .contentShape(Rectangle())
                    .background(tab == item ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}
