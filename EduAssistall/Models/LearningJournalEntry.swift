import Foundation

struct LearningJournalEntry: Identifiable, Codable {
    var id: String
    var studentId: String
    var summary: String
    var keyTopics: [String]
    var sessionDate: Date
    var messageCount: Int

    init(id: String = UUID().uuidString, studentId: String, summary: String,
         keyTopics: [String], sessionDate: Date = Date(), messageCount: Int) {
        self.id = id
        self.studentId = studentId
        self.summary = summary
        self.keyTopics = keyTopics
        self.sessionDate = sessionDate
        self.messageCount = messageCount
    }
}
