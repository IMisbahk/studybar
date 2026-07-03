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

    static func exportSessionsJSON(_ sessions: [StudySession]) -> ExportResult? {
        let formatter = ISO8601DateFormatter()
        let payload: [[String: Any]] = sessions.sorted { $0.startedAt > $1.startedAt }.map { session in
            [
                "startedAt": formatter.string(from: session.startedAt),
                "endedAt": formatter.string(from: session.endedAt),
                "subject": session.subjectName,
                "topic": session.topicName as Any,
                "minutes": Int(session.actualDuration / 60),
                "completed": session.completed,
                "openEnded": session.openEnded,
                "notes": session.notes as Any
            ]
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]) else {
            return nil
        }
        do {
            let url = try uniqueDownloadsURL(preferredName: "studybar-sessions.json")
            try data.write(to: url)
            finishExport(url)
            return ExportResult(url: url, fileName: url.lastPathComponent)
        } catch {
            return nil
        }
    }

    static func exportSessionsMarkdown(_ sessions: [StudySession]) -> ExportResult? {
        let overview = AnalyticsEngine.overview(from: sessions)
        var lines: [String] = [
            "# StudyBar Session Export",
            "",
            "## Summary",
            "",
            "| Metric | Value |",
            "|--------|-------|",
            "| Total hours | \(StudyFormatting.duration(overview.totalStudySeconds)) |",
            "| Sessions | \(overview.totalSessions) |",
            "| Avg session | \(StudyFormatting.duration(overview.averageSessionLength)) |",
            "| Consistency | \(overview.consistencyScore)/100 |",
            "| Focus | \(overview.focusScore)/100 |",
            "",
            "## Sessions",
            ""
        ]
        let formatter = ISO8601DateFormatter()
        for session in sessions.sorted(by: { $0.startedAt > $1.startedAt }) {
            let topic = session.topicName.map { " — \($0)" } ?? ""
            lines.append("- **\(session.subjectName)\(topic)** · \(StudyFormatting.duration(session.actualDuration)) · \(formatter.string(from: session.startedAt))")
            if let notes = session.notes, !notes.isEmpty {
                lines.append("  - \(notes)")
            }
        }
        do {
            let url = try uniqueDownloadsURL(preferredName: "studybar-sessions.md")
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            finishExport(url)
            return ExportResult(url: url, fileName: url.lastPathComponent)
        } catch {
            return nil
        }
    }

    static func savePDF<V: View>(from view: V, size: CGSize, defaultName: String) -> ExportResult? {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard let image = renderer.nsImage else { return nil }

        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: size)
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }
        ctx.beginPDFPage(nil)
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            ctx.draw(cgImage, in: mediaBox)
        }
        ctx.endPDFPage()
        ctx.closePDF()

        do {
            let url = try uniqueDownloadsURL(preferredName: defaultName)
            try pdfData.write(to: url)
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
