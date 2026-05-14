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
    // nil for permanent teacher links; set to 7 days for parent-initiated links.
    // Cloud Function-created teacher links omit this field; making it optional
    // prevents a decode failure that would otherwise empty the teacher roster.
    var expiresAt: Date?

    // Custom decoder so that documents created without `expiresAt` (e.g. by
    // bulkInviteStudents Cloud Function) decode cleanly instead of throwing.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(String.self,   forKey: .id)
        studentId   = try c.decode(String.self,   forKey: .studentId)
        adultId     = try c.decode(String.self,   forKey: .adultId)
        adultRole   = try c.decode(AdultRole.self, forKey: .adultRole)
        studentEmail = try c.decode(String.self,  forKey: .studentEmail)
        confirmed   = try c.decodeIfPresent(Bool.self, forKey: .confirmed) ?? false
        createdAt   = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        expiresAt   = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
    }

    init(studentId: String, adultId: String, adultRole: AdultRole, studentEmail: String) {
        self.id = "\(adultId)_\(studentId)"
        self.studentId = studentId
        self.adultId = adultId
        self.adultRole = adultRole
        self.studentEmail = studentEmail
        // Both parent and teacher links are auto-confirmed — these are authoritative
        // school/family relationships that don't require the student to approve.
        self.confirmed = true
        self.createdAt = Date()
        // Only parent-initiated links carry an expiry. Teacher links are permanent.
        self.expiresAt = adultRole == .parent
            ? Calendar.current.date(byAdding: .day, value: 7, to: Date())
            : nil
    }
}
