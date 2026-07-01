import SwiftUI

struct PopoverRootView: View {
    @Environment(SessionManager.self) private var sessionManager

    var body: some View {
        if sessionManager.phase == .idle {
            IdleView()
        } else {
            ActiveSessionView()
        }
    }
}
