import Foundation

struct Message: Codable, Identifiable {
    var id: String
    var threadId: String
    var senderId: String
    var senderName: String
    var body: String
    var createdAt: Date
    var aiDrafted: Bool

    init(threadId: String, senderId: String, senderName: String,
         body: String, aiDrafted: Bool = false) {
        self.id = UUID().uuidString
        self.threadId = threadId
        self.senderId = senderId
        self.senderName = senderName
        self.body = body
        self.createdAt = Date()
        self.aiDrafted = aiDrafted
    }
}
