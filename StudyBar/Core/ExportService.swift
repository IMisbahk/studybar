import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
enum ExportService {
    static func savePNG<V: View>(from view: V, size: CGSize, defaultName: String) {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? png.write(to: url)
    }

    static func exportSessionsCSV(_ sessions: [StudySession]) {
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

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "studybar-sessions.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    private static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
