import AppKit

final class PowerEventsMonitor {
    private weak var sessionManager: SessionManager?
    private var observers: [NSObjectProtocol] = []

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func start() {
        let workspace = NSWorkspace.shared
        let center = workspace.notificationCenter
        let distributed = DistributedNotificationCenter.default()

        observers.append(center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sessionManager?.pauseBySystem()
        })

        observers.append(center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sessionManager?.resumeIfAutoPaused()
        })

        observers.append(distributed.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sessionManager?.pauseBySystem()
        })

        observers.append(distributed.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.sessionManager?.resumeIfAutoPaused()
        })
    }

    deinit {
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }
}
