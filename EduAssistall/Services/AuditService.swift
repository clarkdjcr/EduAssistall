import Foundation
import FirebaseFirestore

enum AuditEventType: String, Codable {
    case signIn
    case signOut
    case signUp
    case profileUpdated
    case dataExported
    case accountDeleted
    case fcmTokenRefreshed
    case contentViewed
    case testAttempted
    case companionLocked    // FR-106
    case companionUnlocked  // FR-106
}

struct AuditEvent: Codable, Identifiable {
    var id: String
    var userId: String
    var event: AuditEventType
    var metadata: [String: String]
    var createdAt: Date
}

final class AuditService {
    static let shared = AuditService()
    private let db = Firestore.firestore()

    private init() {}

    func log(_ event: AuditEventType, userId: String, metadata: [String: String] = [:]) {
        let entry = AuditEvent(
            id: UUID().uuidString,
            userId: userId,
            event: event,
            metadata: metadata,
            createdAt: Date()
        )
        Task {
            guard let data = try? Firestore.Encoder().encode(entry) else { return }
            try? await db.collection("auditLogs").document(entry.id).setData(data)
        }
    }
}
