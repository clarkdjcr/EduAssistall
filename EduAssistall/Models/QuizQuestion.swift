import Foundation

struct QuizQuestion: Codable, Identifiable {
    var id: String
    var contentItemId: String
    var question: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
    var order: Int
    var createdBy: String
    var createdAt: Date

    init(contentItemId: String, question: String, options: [String],
         correctIndex: Int, explanation: String, order: Int, createdBy: String) {
        self.id = UUID().uuidString
        self.contentItemId = contentItemId
        self.question = question
        self.options = options
        self.correctIndex = correctIndex
        self.explanation = explanation
        self.order = order
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

struct QuizAttempt: Codable, Identifiable {
    var id: String
    var studentId: String
    var contentItemId: String
    var score: Int           // 0–100
    var correctCount: Int
    var totalCount: Int
    var completedAt: Date

    init(studentId: String, contentItemId: String, correctCount: Int, totalCount: Int) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.contentItemId = contentItemId
        self.correctCount = correctCount
        self.totalCount = totalCount
        self.score = totalCount > 0 ? Int(Double(correctCount) / Double(totalCount) * 100) : 0
        self.completedAt = Date()
    }
}
