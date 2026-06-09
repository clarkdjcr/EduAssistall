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
    // nil for normal confirmed teacher links; retained for legacy pending links.
    // Cloud Function-created teacher links omit this field; making it optional
    // prevents a decode failure that would otherwise empty the teacher roster.
    var expiresAt: Date?

    // End-of-year archival fields. Absent on active links.
    var archived: Bool
    var schoolYear: String?   // e.g. "2025-2026"
    var archivedAt: Date?

    // Custom decoder so that documents created without optional fields decode
    // cleanly instead of throwing.
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
        archived    = try c.decodeIfPresent(Bool.self, forKey: .archived) ?? false
        schoolYear  = try c.decodeIfPresent(String.self, forKey: .schoolYear)
        archivedAt  = try c.decodeIfPresent(Date.self, forKey: .archivedAt)
    }

    init(studentId: String, adultId: String, adultRole: AdultRole, studentEmail: String) {
        self.id = "\(adultId)_\(studentId)"
        self.studentId = studentId
        self.adultId = adultId
        self.adultRole = adultRole
        self.studentEmail = studentEmail
        // Parent links are created only after server-side student lookup; teacher
        // links come from teacher invitation/import flows. Both are confirmed.
        self.confirmed = true
        self.createdAt = Date()
        self.expiresAt = nil
        self.archived = false
        self.schoolYear = nil
        self.archivedAt = nil
    }
}
