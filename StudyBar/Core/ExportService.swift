import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ExportResult: Equatable {
    let url: URL
    let fileName: String
}

@MainActor
enum ExportService {
    static func savePNG<V: View>(from view: V, size: CGSize, defaultName: String) -> ExportResult? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return nil }

        do {
            let url = try uniqueDownloadsURL(preferredName: defaultName)
            try png.write(to: url)
            finishExport(url)
            return ExportResult(url: url, fileName: url.lastPathComponent)
        } catch {
            return nil
        }
    }

    static func exportSessionsCSV(_ sessions: [StudySession]) -> ExportResult? {
        var lines = ["date,subject,topic,minutes,completed,open_ended,notes"]
        let formatter = ISO8601DateFormatter()
        for session in sessions.sorted(by: { $0.startedAt > $1.startedAt }) {
            let notes = (session.notes ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let topic = session.topicName ?? ""
            let minutes = Int(session.actualDuration / 60)
            lines.append([
                formatter.string(from: session.startedAt),
                csvField(session.subjectName),
                csvField(topic),
                "\(minutes)",
                session.completed ? "true" : "false",
                session.openEnded ? "true" : "false",
                "\"\(notes)\""
            ].joined(separator: ","))
        }

        do {
            let url = try uniqueDownloadsURL(preferredName: "studybar-sessions.csv")
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            finishExport(url)
            return ExportResult(url: url, fileName: url.lastPathComponent)
        } catch {
            return nil
        }
    }

    static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func openDownloadsFolder() {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
        NSWorkspace.shared.open(downloads)
    }

    private static func finishExport(_ url: URL) {
        NotificationManager.shared.fireExportSaved(fileURL: url)
    }

    private static func uniqueDownloadsURL(preferredName: String) throws -> URL {
        guard let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ExportService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Downloads folder not found"])
        }
        let ext = (preferredName as NSString).pathExtension
        let base = (preferredName as NSString).deletingPathExtension
        var candidate = downloads.appendingPathComponent(preferredName)
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(base)-\(counter)" : "\(base)-\(counter).\(ext)"
            candidate = downloads.appendingPathComponent(name)
            counter += 1
        }
        return candidate
    }

    private static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
