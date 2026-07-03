import Foundation
import AppKit
import UniformTypeIdentifiers

enum BackupService {
    private static let storeFileName = "studybar.store"

    @MainActor
    static func exportBackup() throws -> URL {
        let storeURL = StudyDataStore.canonicalStoreURL()
        let stamp = ISO8601DateFormatter().string(from: Date()).prefix(19).replacingOccurrences(of: ":", with: "-")
        let dest = try ExportService.uniqueDownloadsURL(preferredName: "studybar-backup-\(stamp).zip")
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        for suffix in ["", "-wal", "-shm"] {
            let src = URL(fileURLWithPath: storeURL.path + suffix)
            guard FileManager.default.fileExists(atPath: src.path) else { continue }
            let name = suffix.isEmpty ? storeFileName : storeFileName + suffix
            try FileManager.default.copyItem(at: src, to: temp.appendingPathComponent(name))
        }

        try zipDirectory(temp, to: dest)
        ExportService.revealInFinder(dest)
        return dest
    }

    @MainActor
    static func restoreBackup(from zipURL: URL) throws {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        try unzip(zipURL, to: temp)
        let restoredStore = temp.appendingPathComponent(storeFileName)
        guard FileManager.default.fileExists(atPath: restoredStore.path) else {
            throw NSError(domain: "BackupService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Backup zip does not contain studybar.store"])
        }

        let target = StudyDataStore.canonicalStoreURL()
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)

        let backupStamp = ISO8601DateFormatter().string(from: Date()).prefix(19).replacingOccurrences(of: ":", with: "-")
        for suffix in ["", "-wal", "-shm"] {
            let path = target.path + suffix
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.moveItem(atPath: path, toPath: "\(path).pre-restore-\(backupStamp)")
            }
        }

        for suffix in ["", "-wal", "-shm"] {
            let name = suffix.isEmpty ? storeFileName : storeFileName + suffix
            let src = temp.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: src.path) else { continue }
            try FileManager.default.copyItem(at: src, to: URL(fileURLWithPath: target.path + suffix))
        }

        let alert = NSAlert()
        alert.messageText = "Backup restored"
        alert.informativeText = "StudyBar will quit and reopen to load your restored data."
        alert.addButton(withTitle: "Restart Now")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            UpdateInstaller.isRelaunchPending = true
            let path = Bundle.main.bundlePath
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
                NSApp.terminate(nil)
            }
        }
    }

    @MainActor
    static func pickAndRestore() {
        let panel = NSOpenPanel()
        panel.title = "Restore StudyBar Backup"
        panel.allowedContentTypes = [.zip]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try restoreBackup(from: url)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Restore failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private static func zipDirectory(_ directory: URL, to dest: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-q", dest.path, "."]
        process.currentDirectoryURL = directory
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "BackupService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create backup zip"])
        }
    }

    private static func unzip(_ zip: URL, to dest: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", zip.path, "-d", dest.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "BackupService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not read backup zip"])
        }
    }
}
