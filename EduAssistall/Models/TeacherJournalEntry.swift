import Foundation

/// A private teacher journal entry — daily reflection, typed or (Phase 3) spoken.
///
/// Privacy: STRICTLY owner-only. Stored at `teacherJournal/{teacherId}/entries/{entryId}`,
/// never read by Cloud Functions, excluded from audit logs and data exports. A teacher may
/// *promote* an entry into a `TeacherWikiEntry` (which IS AI-facing) — that promotion is the
/// only path by which journal-derived knowledge becomes visible to generation.
struct TeacherJournalEntry: Identifiable, Codable, Sendable {
    var id: String
    var teacherId: String
    var body: String
    /// "typed" | "voice"
    var source: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    /// Set to the wiki entry id once this reflection has been promoted to the AI-facing wiki.
    var promotedToWikiId: String?

    nonisolated init(id: String = UUID().uuidString,
         teacherId: String,
         body: String,
         source: String = "typed",
         tags: [String] = [],
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         promotedToWikiId: String? = nil) {
        self.id = id
        self.teacherId = teacherId
        self.body = body
        self.source = source
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.promotedToWikiId = promotedToWikiId
    }

    enum CodingKeys: String, CodingKey {
        case id
        case teacherId
        case body
        case source
        case tags
        case createdAt
        case updatedAt
        case promotedToWikiId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        teacherId = try c.decode(String.self, forKey: .teacherId)
        body = try c.decodeIfPresent(String.self, forKey: .body) ?? ""
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "typed"
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        promotedToWikiId = try c.decodeIfPresent(String.self, forKey: .promotedToWikiId)
    }

    var isPromoted: Bool { promotedToWikiId != nil }
}
