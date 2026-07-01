import Foundation
import SwiftData

@Model
final class Subject {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Topic.subject)
    var topics: [Topic] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
