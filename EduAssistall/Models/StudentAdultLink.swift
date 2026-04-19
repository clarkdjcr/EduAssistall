import Foundation

enum AdultRole: String, Codable {
    case teacher
    case parent
}

struct StudentAdultLink: Codable, Identifiable, Hashable {
    var id: String          // Firestore document ID
    var studentId: String
    var adultId: String
    var adultRole: AdultRole
    var studentEmail: String // Used to look up student when linking
    var confirmed: Bool
    var createdAt: Date

    init(studentId: String, adultId: String, adultRole: AdultRole, studentEmail: String) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.adultId = adultId
        self.adultRole = adultRole
        self.studentEmail = studentEmail
        self.confirmed = false
        self.createdAt = Date()
    }
}
