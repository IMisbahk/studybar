import SwiftUI

struct PopoverRootView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var tab: PopoverTab = .timer

    var body: some View {
        VStack(spacing: 0) {
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
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(tab == item ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
}
