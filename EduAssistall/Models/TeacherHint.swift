import Foundation

/// FR-204: A pending hint from a teacher, injected into the AI system prompt on the
/// student's next message. Stored at teacherHints/{studentId} — one document per student.
struct TeacherHint: Codable {
    var text: String
    var teacherId: String
    var teacherName: String
    var consumed: Bool
    var createdAt: Date
}
