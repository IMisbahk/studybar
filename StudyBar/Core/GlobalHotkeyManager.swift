import AppKit

final class GlobalHotkeyManager {
    private weak var sessionManager: SessionManager?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func start() {
        let handler: (NSEvent) -> Void = { [weak self] event in
            self?.handle(event)
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: handler)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handler(event)
            return event
        }
    }

    deinit {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.option), flags.contains(.command) else { return }

        switch event.charactersIgnoringModifiers?.lowercased() {
        case "s":
            sessionManager?.startLastSession()
        case "p":
            sessionManager?.pause()
        case "r":
            sessionManager?.resume()
        case "e":
            sessionManager?.extend(byMinutes: 10)
        case "h":
            sessionManager?.requestOpenHistory()
        default:
            break
        }
    }
}
