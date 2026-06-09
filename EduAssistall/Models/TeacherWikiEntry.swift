import Foundation

/// A teacher-authored knowledge entry that the lesson-plan AI may read to *amplify*
/// daily assignments — analogies, hooks, "what worked," local context, pacing tricks.
///
/// Authority model: a wiki entry is **subordinate** to the state-approved curriculum.
/// At generation time it is injected as a Tier-2 enhancement block under an explicit
/// precedence rule so it can enrich, but never override, the approved standards.
///
/// Storage: `teacherWiki/{teacherId}/entries/{entryId}` — owner-locked (see firestore.rules).
/// `subject`, `gradeLevel`, and `standardCodes` are the cheap metadata keys used to select
/// the few relevant entries for a given assignment, keeping the AI payload (and tokens) small.
struct TeacherWikiEntry: Identifiable, Codable, Sendable {
    var id: String
    var teacherId: String
    var title: String
    var body: String
    var subject: String
    var gradeLevel: String
    var standardCodes: [String]
    var tags: [String]
    /// When false, the entry is kept for the teacher's reference but excluded from AI generation.
    var applyToGeneration: Bool
    var createdAt: Date
    var updatedAt: Date
    /// Set when this entry was promoted from a private journal entry (Phase 2).
    var sourceJournalEntryId: String?

    nonisolated init(id: String = UUID().uuidString,
         teacherId: String,
         title: String,
         body: String,
         subject: String = "",
         gradeLevel: String = "",
         standardCodes: [String] = [],
         tags: [String] = [],
         applyToGeneration: Bool = true,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         sourceJournalEntryId: String? = nil) {
        self.id = id
        self.teacherId = teacherId
        self.title = title
        self.body = body
        self.subject = subject
        self.gradeLevel = gradeLevel
        self.standardCodes = standardCodes
        self.tags = tags
        self.applyToGeneration = applyToGeneration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceJournalEntryId = sourceJournalEntryId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId
        case title
        case body
        case subject
        case gradeLevel
        case standardCodes
        case tags
        case applyToGeneration
        case createdAt
        case updatedAt
        case sourceJournalEntryId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        teacherId = try c.decode(String.self, forKey: .teacherId)
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try c.decodeIfPresent(String.self, forKey: .body) ?? ""
        subject = try c.decodeIfPresent(String.self, forKey: .subject) ?? ""
        gradeLevel = try c.decodeIfPresent(String.self, forKey: .gradeLevel) ?? ""
        standardCodes = try c.decodeIfPresent([String].self, forKey: .standardCodes) ?? []
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        applyToGeneration = try c.decodeIfPresent(Bool.self, forKey: .applyToGeneration) ?? true
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        sourceJournalEntryId = try c.decodeIfPresent(String.self, forKey: .sourceJournalEntryId)
    }
}
