import Foundation
import SwiftData

@Model
final class Subject {
    var name: String
    var createdAt: Date
    var isPinned: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Topic.subject)
    var topics: [Topic] = []

    init(name: String, isPinned: Bool = false) {
        self.name = name
        self.createdAt = Date()
        self.isPinned = isPinned
    }
}
