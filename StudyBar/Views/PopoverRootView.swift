import SwiftUI

private enum PopoverTab: String, CaseIterable {
    case timer
    case history
    case settings

    var title: String {
        switch self {
        case .timer: "Timer"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .timer: "timer"
        case .history: "clock.arrow.circlepath"
        case .settings: "gearshape"
        }
    }
}

struct PopoverRootView: View {
    @Environment(SessionManager.self) private var sessionManager
    @State private var tab: PopoverTab = .timer

    var body: some View {
        VStack(spacing: 0) {
            content
            Divider()
            tabBar
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
                tabButton(item)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }

    private func tabButton(_ target: PopoverTab) -> some View {
        Button {
            tab = target
        } label: {
            VStack(spacing: 2) {
                Image(systemName: target.systemImage)
                    .font(.system(size: 14))
                Text(target.title)
                    .font(.caption2)
            }
            .foregroundStyle(tab == target ? Color.accentColor : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(tab == target ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
