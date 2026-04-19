import Foundation

enum ContentType: String, Codable, CaseIterable {
    case video
    case article
    case quiz

    var displayName: String {
        switch self {
        case .video:   return "Video"
        case .article: return "Article"
        case .quiz:    return "Quiz"
        }
    }

    var icon: String {
        switch self {
        case .video:   return "play.rectangle.fill"
        case .article: return "doc.text.fill"
        case .quiz:    return "checkmark.square.fill"
        }
    }
}

struct ContentItem: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var contentType: ContentType
    var url: String
    var subject: String
    var gradeLevel: String
    var estimatedMinutes: Int
    var createdBy: String
    var createdAt: Date
    var source: String?             // "khanacademy", "edx", nil = manual entry
    var externalId: String?         // original platform content ID
    var alignedStandards: [String]  // CCSS/NGSS standard codes

    init(title: String, description: String, contentType: ContentType,
         url: String, subject: String, gradeLevel: String,
         estimatedMinutes: Int, createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.contentType = contentType
        self.url = url
        self.subject = subject
        self.gradeLevel = gradeLevel
        self.estimatedMinutes = estimatedMinutes
        self.createdBy = createdBy
        self.createdAt = Date()
        self.alignedStandards = []
    }
}
