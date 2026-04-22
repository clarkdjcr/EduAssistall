import Foundation
import SwiftData

// SwiftData persistence models for offline cache (replaces UserDefaults blobs).
// These are cache-layer types — not Firestore models. Firestore structs are converted
// to/from these classes inside OfflineCacheService; nothing else should import them.

@Model
final class CachedLearningPath {
    @Attribute(.unique) var id: String
    var studentId: String
    var title: String
    var pathDescription: String   // 'description' conflicts with CustomStringConvertible
    var isActive: Bool
    var answerModeEnabled: Bool
    var createdAt: Date
    var cachedAt: Date
    var itemsData: Data           // JSON-encoded [LearningPathItem]

    init(id: String, studentId: String, title: String, pathDescription: String,
         isActive: Bool, answerModeEnabled: Bool, createdAt: Date, itemsData: Data) {
        self.id = id
        self.studentId = studentId
        self.title = title
        self.pathDescription = pathDescription
        self.isActive = isActive
        self.answerModeEnabled = answerModeEnabled
        self.createdAt = createdAt
        self.cachedAt = Date()
        self.itemsData = itemsData
    }
}

@Model
final class CachedStudentProgress {
    @Attribute(.unique) var id: String   // "\(studentId)_\(contentItemId)"
    var studentId: String
    var contentItemId: String
    var statusRaw: String                // CompletionStatus.rawValue
    var completionPercent: Int
    var timeSpentMinutes: Int
    var completedAt: Date?
    var updatedAt: Date
    var cachedAt: Date

    init(id: String, studentId: String, contentItemId: String, statusRaw: String,
         completionPercent: Int, timeSpentMinutes: Int, completedAt: Date?, updatedAt: Date) {
        self.id = id
        self.studentId = studentId
        self.contentItemId = contentItemId
        self.statusRaw = statusRaw
        self.completionPercent = completionPercent
        self.timeSpentMinutes = timeSpentMinutes
        self.completedAt = completedAt
        self.updatedAt = updatedAt
        self.cachedAt = Date()
    }
}
