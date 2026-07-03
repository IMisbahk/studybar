import Foundation
import SwiftData

// subjectName/topicName are denormalized snapshots, not relationships -
// history should still read fine even if a subject gets renamed or deleted later
@Model
final class StudySession {
    var subjectName: String
    var topicName: String?
    var plannedDuration: TimeInterval
    var actualDuration: TimeInterval
    var startedAt: Date
    var endedAt: Date
    var completed: Bool
    var notes: String?
    var openEnded: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \SessionSegment.session)
    var segments: [SessionSegment] = []

    init(
        subjectName: String,
        topicName: String?,
        plannedDuration: TimeInterval,
        actualDuration: TimeInterval,
        startedAt: Date,
        endedAt: Date,
        completed: Bool,
        notes: String? = nil,
        openEnded: Bool = false
    ) {
        self.subjectName = subjectName
        self.topicName = topicName
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.completed = completed
        self.notes = notes
        self.openEnded = openEnded
    }
}
