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
