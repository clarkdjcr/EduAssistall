import Foundation
import FirebaseFunctions

// MARK: - CompanionError

/// Typed errors returned by askCompanion. All raw Firebase/network errors are
/// translated here so views never need to inspect FunctionsErrorCode directly.
enum CompanionError: LocalizedError {
    /// Per-user hourly call limit reached (server rate limit).
    case rateLimited
    /// Educator has paused this student's companion session (kill switch).
    case sessionLocked
    /// Claude API is temporarily down or overloaded.
    case aiUnavailable
    /// Claude API call timed out.
    case aiTimeout
    /// Device has no network connectivity.
    case offline
    /// Any other unexpected failure.
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "You've reached your message limit for this hour. You can send more messages after the hour resets."
        case .sessionLocked:
            return "Your companion session has been paused by your educator. Please speak with them to continue."
        case .aiUnavailable:
            return "The AI is temporarily unavailable. Please try again in a moment."
        case .aiTimeout:
            return "The AI took too long to respond. Please try again."
        case .offline:
            return "You appear to be offline. Please check your connection and try again."
        case .unknown(let detail):
            return detail.isEmpty ? "Something went wrong. Please try again." : detail
        }
    }

    /// True for transient errors the user can immediately retry.
    var isRetryable: Bool {
        switch self {
        case .aiUnavailable, .aiTimeout, .offline, .unknown: return true
        case .rateLimited, .sessionLocked: return false
        }
    }
}

// MARK: - Catalog Item (returned by curateContent Cloud Function)

struct CatalogItem: Identifiable {
    let externalId: String
    let title: String
    let description: String
    let contentType: String       // "video" | "article"
    let url: String
    let source: String            // "khanacademy" | "edx"
    let subject: String
    let estimatedMinutes: Int

    var id: String { externalId }

    init?(from dict: [String: Any], defaultSubject: String) {
        guard let externalId = dict["externalId"] as? String,
              let title = dict["title"] as? String,
              let url = dict["url"] as? String,
              !url.isEmpty, url != "https://www.khanacademy.org" else { return nil }
        self.externalId = externalId
        self.title = title
        self.description = dict["description"] as? String ?? ""
        self.contentType = dict["contentType"] as? String ?? "video"
        self.url = url
        self.source = dict["source"] as? String ?? "khanacademy"
        self.subject = dict["subject"] as? String ?? defaultSubject
        self.estimatedMinutes = dict["estimatedMinutes"] as? Int ?? 8
    }

    func toContentItem(teacherId: String, gradeLevel: String) -> ContentItem {
        var item = ContentItem(
            title: title,
            description: description,
            contentType: contentType == "video" ? .video : .article,
            url: url,
            subject: subject,
            gradeLevel: gradeLevel,
            estimatedMinutes: estimatedMinutes,
            createdBy: teacherId
        )
        item.source = source
        item.externalId = externalId
        return item
    }
}

// MARK: - Service

final class CloudFunctionService {
    static let shared = CloudFunctionService()
    private lazy var functions = Functions.functions(region: "us-central1")

    private init() {}

    func generateRecommendations(studentId: String) async throws {
        let data: [String: Any] = ["studentId": studentId]
        _ = try await functions.httpsCallable("generateRecommendations").call(data)
    }

    func curateContent(subject: String, gradeLevel: String, source: String = "khanacademy") async throws -> [CatalogItem] {
        let data: [String: Any] = ["subject": subject, "gradeLevel": gradeLevel, "source": source]
        let result = try await functions.httpsCallable("curateContent").call(data)
        guard let dict = result.data as? [String: Any],
              let rawItems = dict["items"] as? [[String: Any]] else { return [] }
        return rawItems.compactMap { CatalogItem(from: $0, defaultSubject: subject) }
    }

    func bulkInviteStudents(students: [[String: Any]], teacherName: String) async throws -> ImportResult {
        let data: [String: Any] = ["students": students, "teacherName": teacherName]
        let result = try await functions.httpsCallable("bulkInviteStudents").call(data)
        guard let dict = result.data as? [String: Any] else { throw URLError(.badServerResponse) }
        return ImportResult(
            invited: dict["invited"] as? Int ?? 0,
            alreadyExisted: dict["alreadyExisted"] as? Int ?? 0,
            errorCount: (dict["errors"] as? [[String: Any]])?.count ?? 0
        )
    }

    /// Looks up a student by email server-side. Only callable by users with role == "parent".
    /// Returns (studentId, displayName) — never the full UserProfile.
    func lookupStudentByEmail(_ email: String) async throws -> (studentId: String, displayName: String) {
        let result = try await functions.httpsCallable("lookupStudentByEmail").call(["email": email])
        guard let dict = result.data as? [String: Any],
              let studentId = dict["studentId"] as? String,
              let displayName = dict["displayName"] as? String else {
            throw URLError(.badServerResponse)
        }
        return (studentId, displayName)
    }

    func importClassroomRoster(googleAccessToken: String, teacherId: String) async throws -> Int {
        let data: [String: Any] = ["googleAccessToken": googleAccessToken, "teacherId": teacherId]
        let result = try await functions.httpsCallable("importClassroomRoster").call(data)
        return (result.data as? [String: Any])?["imported"] as? Int ?? 0
    }

    /// FR-002: Record a learning milestone so the companion can reference it cross-session.
    func recordMilestone(studentId: String, type: MilestoneType, title: String, subject: String) async throws {
        let data: [String: Any] = [
            "studentId": studentId,
            "type": type.rawValue,
            "title": title,
            "subject": subject,
        ]
        _ = try? await functions.httpsCallable("recordMilestone").call(data)
    }

    /// FR-403: Request a full data export for a student. Returns pretty-printed JSON string.
    func requestDataExport(studentId: String) async throws -> String {
        let result = try await functions.httpsCallable("requestDataExport").call(["studentId": studentId])
        guard let dict = result.data as? [String: Any],
              let exportObj = dict["export"] else {
            throw URLError(.badServerResponse)
        }
        let data = try JSONSerialization.data(withJSONObject: exportObj, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// FR-302: Ask the server to generate a learning journal entry for the just-completed session.
    /// Fire-and-forget — caller should not await or handle errors.
    func generateJournalEntry(studentId: String, conversationId: String) {
        Task {
            _ = try? await functions.httpsCallable("generateJournalEntry").call([
                "studentId": studentId,
                "conversationId": conversationId,
            ])
        }
    }

    func askCompanion(
        message: String,
        studentId: String,
        mode: InteractionMode = .guidedDiscovery,
        compressedHistory: String? = nil
    ) async throws -> String {
        var data: [String: Any] = [
            "message": message,
            "studentId": studentId,
            "conversationId": studentId,
            "interactionMode": mode.rawValue,
        ]
        if let compressed = compressedHistory {
            data["compressedHistory"] = compressed
        }
        do {
            let result = try await functions.httpsCallable("askCompanion").call(data)
            guard let dict = result.data as? [String: Any],
                  let reply = dict["reply"] as? String else {
                throw CompanionError.unknown("")
            }
            return reply
        } catch let error as NSError {
            throw companionError(from: error)
        }
    }

    /// Translates any NSError from the Firebase Functions SDK into a typed CompanionError.
    private func companionError(from error: NSError) -> CompanionError {
        // Already a CompanionError (e.g. from the guard above) — pass through.
        if let ce = error as? CompanionError { return ce }

        // Network unreachable — check before Firebase codes so URLError is caught too.
        if error.domain == NSURLErrorDomain {
            let code = URLError.Code(rawValue: error.code)
            if [.notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost].contains(code) {
                return .offline
            }
            return .aiUnavailable
        }

        // Firebase Functions errors carry the gRPC status code in the error code field.
        guard error.domain == FunctionsErrorDomain else {
            return .unknown("")
        }

        switch FunctionsErrorCode(rawValue: error.code) {
        case .resourceExhausted:  return .rateLimited
        case .permissionDenied:   return .sessionLocked
        case .unavailable:        return .aiUnavailable
        case .deadlineExceeded:   return .aiTimeout
        case .unauthenticated:
            // Surface the server message directly — it says "Must be signed in."
            return .unknown(error.localizedDescription)
        default:
            return .unknown("")
        }
    }
}
