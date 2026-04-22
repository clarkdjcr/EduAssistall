import Foundation

/// FR-203: Teacher-level classroom defaults stored at classroomConfig/{teacherId}.
/// Applied as initial values when configuring a new student via ClassroomConfigView.
struct ClassroomConfig: Codable, Identifiable {
    var id: String               // equals teacherId
    var teacherId: String
    var defaultInteractionMode: InteractionMode
    var allowedInteractionModes: [InteractionMode]
    var answerModeEnabledByDefault: Bool
    var responseStyle: ResponseStyle

    init(teacherId: String) {
        self.id = teacherId
        self.teacherId = teacherId
        self.defaultInteractionMode = .guidedDiscovery
        self.allowedInteractionModes = InteractionMode.allCases
        self.answerModeEnabledByDefault = false
        self.responseStyle = .standard
    }
}

/// FR-204: A pending hint from a teacher, injected into the AI system prompt on the
/// student's next message. Stored at teacherHints/{studentId} — one document per student.
struct TeacherHint: Codable {
    var text: String
    var teacherId: String
    var teacherName: String
    var consumed: Bool
    var createdAt: Date
}
