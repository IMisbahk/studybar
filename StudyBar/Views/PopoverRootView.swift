import SwiftUI

struct PopoverRootView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var tab: PopoverTab = .timer

    var body: some View {
        VStack(spacing: 0) {
            popoverHeader
            content
            Divider()
            tabBar
        }
        .frame(width: 300)
        .onAppear {
            tab = sessionManager.selectedTab
            NotificationCenter.default.post(name: .studyBarMenuPopoverVisible, object: true)
        }
        .onDisappear {
            NotificationCenter.default.post(name: .studyBarMenuPopoverVisible, object: false)
        }
        .onChange(of: sessionManager.selectedTab) { _, newTab in
            tab = newTab
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
