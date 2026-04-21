import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let text: String
    let createdAt: Date

    init(role: MessageRole, text: String) {
        self.id = UUID().uuidString
        self.role = role
        self.text = text
        self.createdAt = Date()
    }

    init(id: String, role: MessageRole, text: String, createdAt: Date) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

/// Tracks whether a student has an active companion session (FR-200).
/// Written at `activeSessions/{studentId}`.
struct ActiveSession: Codable, Identifiable {
    var id: String          // equals studentId
    var studentId: String
    var studentEmail: String
    var isActive: Bool
    var startedAt: Date?
    var lastMessageAt: Date?
    var messageCount: Int
}
