import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case overview
    case profile
    case galaxy
    case achievements
    case analytics
    case notes
    case timeline
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .profile: "Profile"
        case .galaxy: "Galaxy"
        case .achievements: "Achievements"
        case .analytics: "Analytics"
        case .notes: "Notes"
        case .timeline: "Timeline"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "chart.bar.fill"
        case .profile: "person.crop.circle.fill"
        case .galaxy: "globe.americas.fill"
        case .achievements: "medal.fill"
        case .analytics: "square.grid.3x3.fill"
        case .notes: "note.text"
        case .timeline: "timeline.selection"
        case .settings: "gearshape.fill"
        }
    }
}

struct DashboardView: View {
    @State private var section: DashboardSection
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    init(initialSection: DashboardSection = .overview) {
        _section = State(initialValue: initialSection)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            ZStack(alignment: .top) {
                detailContent
                AchievementUnlockBanner()
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 720, minHeight: 480)
        .onReceive(NotificationCenter.default.publisher(for: .studyBarOpenDashboard)) { note in
            if let target = note.object as? DashboardSection {
                section = target
            }
        }
    }

    private var sidebar: some View {
        List(selection: $section) {
            Section("StudyBar") {
                ForEach(DashboardSection.allCases) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("StudyBar")
        .frame(minWidth: 200)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch section {
        case .overview:
            DashboardOverviewView()
        case .profile:
            ProfileDashboardView()
        case .galaxy:
            GalaxyView()
        case .achievements:
            AchievementsView()
        case .analytics:
            AnalyticsDashboardView()
        case .notes:
            NotesBrowserView()
        case .timeline:
            TimelineView()
        case .settings:
            DashboardSettingsView()
        }
    }
}
