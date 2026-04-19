import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable {
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
}
