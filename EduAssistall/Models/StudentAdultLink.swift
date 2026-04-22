import Foundation

enum AdultRole: String, Codable {
    case teacher
    case parent
}

struct StudentAdultLink: Codable, Identifiable, Hashable {
    var id: String          // Firestore document ID — "{adultId}_{studentId}"
    var studentId: String
    var adultId: String
    var adultRole: AdultRole
    var studentEmail: String
    var confirmed: Bool
    var createdAt: Date
    var expiresAt: Date     // COPPA: pending requests expire after 7 days

    init(studentId: String, adultId: String, adultRole: AdultRole, studentEmail: String) {
        self.id = "\(adultId)_\(studentId)"
        self.studentId = studentId
        self.adultId = adultId
        self.adultRole = adultRole
        self.studentEmail = studentEmail
        self.confirmed = false
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
}
