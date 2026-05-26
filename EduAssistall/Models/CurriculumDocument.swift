import Foundation
import FirebaseFirestore

struct CurriculumDocEntry: Identifiable {
    let id: String
    let title: String
    let subject: String
    let gradeLevel: String
    let standard: String
    let collectionType: String   // "curriculum" | "grounding"
    let content: String
    let createdAt: Date?
    let uploadedBy: String
    let districtId: String?

    init?(from snap: DocumentSnapshot, collectionType: String) {
        guard let data = snap.data() else { return nil }
        id                   = snap.documentID
        title                = data["title"]       as? String ?? "Untitled"
        subject              = data["subject"]      as? String ?? ""
        gradeLevel           = data["gradeLevel"]   as? String ?? ""
        standard             = data["standard"]     as? String ?? ""
        content              = data["content"]      as? String ?? ""
        createdAt            = (data["createdAt"] as? Timestamp)?.dateValue()
        uploadedBy           = data["uploadedBy"]   as? String ?? ""
        districtId           = data["districtId"]   as? String
        self.collectionType  = collectionType
    }

    var wordCount: Int {
        content.split(whereSeparator: \.isWhitespace).count
    }

    var collectionDisplayName: String {
        collectionType == "grounding" ? "Grounding" : "Curriculum"
    }

    var collectionColor: String {
        collectionType == "grounding" ? "purple" : "blue"
    }
}
