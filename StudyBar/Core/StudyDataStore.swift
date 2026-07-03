import Foundation
import SQLite3
import SwiftData

enum StudyDataStore {
    private static let schema = Schema([Subject.self, Topic.self, StudySession.self])
    private static let storeFileName = "studybar.store"

    static func makeContainer() throws -> ModelContainer {
        let storeURL = canonicalStoreURL()
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try migrateLegacyStoresIfNeeded(to: storeURL)

        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            try backupStoreFiles(at: storeURL)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    // fixed path — never depends on sandbox vs non-sandbox layout
    static func canonicalStoreURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("StudyBar", isDirectory: true)
            .appendingPathComponent(storeFileName)
    }

    private static func legacyStoreCandidates() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            // sandboxed builds (v1.0 – v1.5.2)
            home.appendingPathComponent("Library/Containers/com.misbah.studybar/Data/Library/Application Support/default.store"),
            // v1.5.3 accidentally used the global default name
            home.appendingPathComponent("Library/Application Support/default.store"),
        ]
    }

    private static func migrateLegacyStoresIfNeeded(to target: URL) throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: target.path), sessionCount(at: target) > 0 {
            return
        }

        for legacy in legacyStoreCandidates() {
            guard legacy != target, fm.fileExists(atPath: legacy.path) else { continue }
            let count = sessionCount(at: legacy)
            guard count > 0 else { continue }
            try copyStore(from: legacy, to: target)
            return
        }
    }

    private static func sessionCount(at storeURL: URL) -> Int {
        var db: OpaquePointer?
        guard sqlite3_open_v2(storeURL.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM ZSTUDYSESSION"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    private static func copyStore(from source: URL, to target: URL) throws {
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let src = source.path + suffix
            let dst = target.path + suffix
            guard fm.fileExists(atPath: src) else { continue }
            try? fm.removeItem(atPath: dst)
            try fm.copyItem(atPath: src, toPath: dst)
        }
    }

    private static func backupStoreFiles(at storeUrl: URL) throws {
        let fm = FileManager.default
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let suffix = "backup-\(stamp)"

        for path in [storeUrl.path, storeUrl.path + "-wal", storeUrl.path + "-shm"] {
            guard fm.fileExists(atPath: path) else { continue }
            let backupPath = "\(path).\(suffix)"
            try? fm.removeItem(atPath: backupPath)
            try fm.moveItem(atPath: path, toPath: backupPath)
        }
    }
}
