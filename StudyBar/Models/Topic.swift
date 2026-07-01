import Foundation
import SwiftData

@Model
final class Topic {
    var name: String
    var subject: Subject?

    init(name: String, subject: Subject? = nil) {
        self.name = name
        self.subject = subject
    }
}
