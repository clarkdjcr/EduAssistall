// IMPORTANT: Add FirebaseStorage to the Xcode target before building.
// In Xcode: select the EduAssistall target → Frameworks, Libraries, and Embedded Content
// → click + → search "FirebaseStorage" → Add.
// (FirebaseStorage is already present in your firebase-ios-sdk SPM package.)
import Foundation
import FirebaseStorage

final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()

    private init() {}

    /// Uploads raw data to `path` and returns the canonical storage path and public download URL.
    func upload(data: Data, path: String, mimeType: String) async throws -> (storagePath: String, downloadURL: String) {
        let ref = storage.reference().child(path)
        let meta = StorageMetadata()
        meta.contentType = mimeType
        _ = try await ref.putDataAsync(data, metadata: meta)
        let url = try await ref.downloadURL()
        return (path, url.absoluteString)
    }

    func delete(path: String) async throws {
        try await storage.reference().child(path).delete()
    }

    // MARK: - Convenience path builders

    static func submissionPath(studentId: String, threadId: String, filename: String) -> String {
        "submissions/\(studentId)/\(threadId)/\(filename)"
    }

    static func individualFilePath(studentId: String, filename: String) -> String {
        "files/students/\(studentId)/\(filename)"
    }

    static func groupFilePath(groupId: String, filename: String) -> String {
        "files/groups/\(groupId)/\(filename)"
    }
}
