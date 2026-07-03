import AppKit

final class GlobalHotkeyManager {
    static weak var shared: GlobalHotkeyManager?

    private weak var sessionManager: SessionManager?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func start() {
        Self.shared = self
        startLocalMonitor()
        refreshGlobalMonitor()
    }

    func refreshGlobalMonitor() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        guard UserDefaults.standard.bool(forKey: "globalHotkeysEnabled"),
              PermissionsHelper.hasAccessibility else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
    }

    private func startLocalMonitor() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
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
            Task { @MainActor in sessionManager?.requestOpenHistory() }
        default:
            break
        }
    }
}
