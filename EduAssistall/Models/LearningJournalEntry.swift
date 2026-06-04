import Foundation

struct LearningJournalEntry: Identifiable, Codable {
    var id: String
    var studentId: String
    var summary: String
    var keyTopics: [String]
    var sessionDate: Date
    var messageCount: Int
    var privateReflection: String?
    var shareWithTeacher: Bool
    var shareWithParent: Bool
    var reflectionSafetyStatus: String?
    var reflectionSafetyReason: String?
    var reflectionUpdatedAt: Date?

    init(id: String = UUID().uuidString, studentId: String, summary: String,
         keyTopics: [String], sessionDate: Date = Date(), messageCount: Int) {
        self.id = id
        self.studentId = studentId
        self.summary = summary
        self.keyTopics = keyTopics
        self.sessionDate = sessionDate
        self.messageCount = messageCount
        self.privateReflection = nil
        self.shareWithTeacher = false
        self.shareWithParent = false
        self.reflectionSafetyStatus = nil
        self.reflectionSafetyReason = nil
        self.reflectionUpdatedAt = nil
    }

    enum CodingKeys: String, CodingKey {
        case id
        case studentId
        case summary
        case keyTopics
        case sessionDate
        case messageCount
        case privateReflection
        case shareWithTeacher
        case shareWithParent
        case reflectionSafetyStatus
        case reflectionSafetyReason
        case reflectionUpdatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        studentId = try c.decode(String.self, forKey: .studentId)
        summary = try c.decode(String.self, forKey: .summary)
        keyTopics = try c.decodeIfPresent([String].self, forKey: .keyTopics) ?? []
        sessionDate = try c.decodeIfPresent(Date.self, forKey: .sessionDate) ?? Date()
        messageCount = try c.decodeIfPresent(Int.self, forKey: .messageCount) ?? 0
        privateReflection = try c.decodeIfPresent(String.self, forKey: .privateReflection)
        shareWithTeacher = try c.decodeIfPresent(Bool.self, forKey: .shareWithTeacher) ?? false
        shareWithParent = try c.decodeIfPresent(Bool.self, forKey: .shareWithParent) ?? false
        reflectionSafetyStatus = try c.decodeIfPresent(String.self, forKey: .reflectionSafetyStatus)
        reflectionSafetyReason = try c.decodeIfPresent(String.self, forKey: .reflectionSafetyReason)
        reflectionUpdatedAt = try c.decodeIfPresent(Date.self, forKey: .reflectionUpdatedAt)
    }

    var displaySummary: String {
        Self.cleanedJournalSummary(from: summary)
    }

    var displayKeyTopics: [String] {
        let parsed = Self.parsedJournalPayload(from: summary)
        let topics = parsed?.keyTopics ?? keyTopics
        return topics
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func cleanedJournalSummary(from value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let parsed = parsedJournalPayload(from: trimmed), !parsed.summary.isEmpty {
            return parsed.summary
        }
        return trimmed
    }

    private static func parsedJournalPayload(from value: String) -> (summary: String, keyTopics: [String])? {
        guard let json = extractedJSONObjectString(from: value),
              let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let summary = (object["summary"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let topics = (object["keyTopics"] as? [String] ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return summary.isEmpty ? nil : (summary, topics)
    }

    private static func extractedJSONObjectString(from value: String) -> String? {
        var text = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else {
            return nil
        }
        return String(text[start...end])
    }
}
