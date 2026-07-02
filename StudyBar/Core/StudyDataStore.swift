import Foundation
import SwiftData

enum StudyDataStore {
    private static let schema = Schema([Subject.self, Topic.self, StudySession.self])

    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            try backupStoreFiles(at: config.url)
            return try ModelContainer(for: schema, configurations: [config])
        }
    }

    private static func backupStoreFiles(at storeUrl: URL) throws {
        let fm = FileManager.default
        let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let base = storeUrl.deletingPathExtension()
        let suffix = "backup-\(stamp)"

        for path in [storeUrl.path, "\(base.path)-wal", "\(base.path)-shm"] {
            guard fm.fileExists(atPath: path) else { continue }
            let backupPath = "\(path).\(suffix)"
            try? fm.removeItem(atPath: backupPath)
            try fm.moveItem(atPath: path, toPath: backupPath)
        }
    }
}
