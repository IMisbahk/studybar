import SwiftUI

private enum PopoverTab {
    case timer
    case history
    case settings
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
        HStack(spacing: 32) {
            tabButton(.timer, systemImage: "timer")
            tabButton(.history, systemImage: "clock.arrow.circlepath")
            tabButton(.settings, systemImage: "gearshape")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private func tabButton(_ target: PopoverTab, systemImage: String) -> some View {
        Button {
            tab = target
        } label: {
            Image(systemName: systemImage)
                .foregroundStyle(tab == target ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
    }
}
