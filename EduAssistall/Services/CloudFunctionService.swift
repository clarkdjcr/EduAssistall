import Foundation
import FirebaseFunctions

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

    func curateContent(subject: String, gradeLevel: String) async throws -> [CatalogItem] {
        let data: [String: Any] = ["subject": subject, "gradeLevel": gradeLevel]
        let result = try await functions.httpsCallable("curateContent").call(data)
        guard let dict = result.data as? [String: Any],
              let rawItems = dict["items"] as? [[String: Any]] else { return [] }
        return rawItems.compactMap { CatalogItem(from: $0, defaultSubject: subject) }
    }

    func askCompanion(message: String, studentId: String) async throws -> String {
        let data: [String: Any] = [
            "message": message,
            "studentId": studentId,
            "conversationId": studentId  // one persistent conversation per student
        ]
        let result = try await functions.httpsCallable("askCompanion").call(data)
        guard let dict = result.data as? [String: Any],
              let reply = dict["reply"] as? String else {
            throw URLError(.badServerResponse)
        }
        return reply
    }
}
