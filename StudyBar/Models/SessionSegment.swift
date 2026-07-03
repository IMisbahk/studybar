import Foundation
import SwiftData

enum SessionSegmentKind: String, Codable, CaseIterable {
    case active
    case pause
    case systemPause

    var label: String {
        switch self {
        case .active: "Studying"
        case .pause: "Paused"
        case .systemPause: "Auto-paused"
        }
    }
}

// pause/resume intervals persisted per session — timeline needs this shit
@Model
final class SessionSegment {
    var kindRaw: String
    var startedAt: Date
    var endedAt: Date

    var session: StudySession?

    var kind: SessionSegmentKind {
        get { SessionSegmentKind(rawValue: kindRaw) ?? .active }
        set { kindRaw = newValue.rawValue }
    }

    init(kind: SessionSegmentKind, startedAt: Date, endedAt: Date) {
        self.kindRaw = kind.rawValue
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
