import Foundation

struct LearningPathItem: Codable, Identifiable {
    var id: String
    var contentItemId: String
    var order: Int

    init(contentItemId: String, order: Int) {
        self.id = UUID().uuidString
        self.contentItemId = contentItemId
        self.order = order
    }
}

struct LearningPath: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var studentId: String
    var createdBy: String
    var items: [LearningPathItem]
    var isActive: Bool
    var createdAt: Date
    /// FR-006: When false (default), the companion scaffolds but never gives direct answers.
    /// Educators must explicitly enable this per path for answer-mode to activate.
    var answerModeEnabled: Bool

    init(title: String, description: String, studentId: String, createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.studentId = studentId
        self.createdBy = createdBy
        self.items = []
        self.isActive = true
        self.createdAt = Date()
        self.answerModeEnabled = false
    }

    var sortedItems: [LearningPathItem] {
        items.sorted { $0.order < $1.order }
    }
}
