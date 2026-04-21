import Foundation

/// Represents an educator-activated session lock for a student's AI companion (FR-106).
/// Stored at companionLocks/{studentId}. Absence of a document = unlocked.
struct CompanionLock: Codable, Identifiable {
    var id: String          // equals studentId
    var studentId: String
    var isLocked: Bool
    var lockedBy: String?       // educator UID
    var lockedByName: String?
    var reason: String
    var lockedAt: Date?
    var unlockedAt: Date?
}
