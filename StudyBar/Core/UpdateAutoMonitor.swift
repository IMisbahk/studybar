import Foundation
import SwiftData

@MainActor
final class UpdateAutoMonitor {
    static let shared = UpdateAutoMonitor()

    private weak var sessionManager: SessionManager?
    private var timer: Timer?
    private var isChecking = false

    private let interval: TimeInterval = 6 * 3600

    private init() {}

    func configure(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func start() {
        timer?.invalidate()
        guard UserDefaults.standard.bool(forKey: "autoUpdateEnabled") else { return }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndApplyUpdate()
            }
        }
        Task {
            try? await Task.sleep(for: .seconds(30))
            await checkAndApplyUpdate()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func restartIfNeeded() {
        stop()
        start()
    }

    func checkAndApplyUpdate() async {
        guard UserDefaults.standard.bool(forKey: "autoUpdateEnabled") else { return }
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        let status = await UpdateChecker.check()
        guard case .updateAvailable(let latest, _) = status else { return }
        guard let asset = await UpdateInstaller.fetchLatestAsset(), asset.version == latest else { return }

        let dest = try? UpdateInstaller.updatesDirectory().appendingPathComponent("StudyBar-\(asset.version).dmg")
        if let dest, FileManager.default.fileExists(atPath: dest.path) {
            await applyIfIdle(dmgPath: dest, version: latest)
            return
        }

        do {
            let path = try await UpdateInstaller.download(asset: asset) { _ in }
            await applyIfIdle(dmgPath: path, version: latest)
        } catch {
            print("Auto-update download failed: \(error)")
        }
    }

    private func applyIfIdle(dmgPath: URL, version: String) async {
        guard sessionManager?.phase == .idle else {
            UserDefaults.standard.set(dmgPath.path, forKey: "pendingAutoUpdateDmg")
            UserDefaults.standard.set(version, forKey: "pendingAutoUpdateVersion")
            return
        }
        guard UserDefaults.standard.bool(forKey: "autoUpdateInstallEnabled") else { return }
        do {
            try UpdateInstaller.installAndRelaunch(dmgPath: dmgPath)
        } catch {
            print("Auto-update install failed: \(error)")
        }
    }

    func applyPendingUpdateIfIdle() {
        guard sessionManager?.phase == .idle else { return }
        guard UserDefaults.standard.bool(forKey: "autoUpdateInstallEnabled") else { return }
        guard let path = UserDefaults.standard.string(forKey: "pendingAutoUpdateDmg") else { return }
        let dmg = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: dmg.path) else {
            UserDefaults.standard.removeObject(forKey: "pendingAutoUpdateDmg")
            return
        }
        do {
            try UpdateInstaller.installAndRelaunch(dmgPath: dmg)
        } catch {
            print("Pending auto-update failed: \(error)")
        }
    }
}
