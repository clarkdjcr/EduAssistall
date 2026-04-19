import Foundation

struct MessageThread: Codable, Identifiable {
    var id: String
    var participants: [String]              // userIds
    var participantNames: [String: String]  // userId → displayName
    var studentId: String
    var studentName: String
    var lastMessage: String?
    var lastMessageAt: Date?
    var createdAt: Date

    init(participants: [String], participantNames: [String: String],
         studentId: String, studentName: String) {
        self.id = UUID().uuidString
        self.participants = participants
        self.participantNames = participantNames
        self.studentId = studentId
        self.studentName = studentName
        self.createdAt = Date()
    }

    func otherParticipantName(currentUserId: String) -> String {
        participantNames
            .filter { $0.key != currentUserId }
            .values
            .joined(separator: ", ")
    }
}
