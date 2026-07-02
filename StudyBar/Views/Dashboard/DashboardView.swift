import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case overview
    case history
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "chart.bar.fill"
        case .history: "clock.arrow.circlepath"
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
            detailContent
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
        case .history:
            DashboardHistoryView()
        case .settings:
            DashboardSettingsView()
        }
    }
}
