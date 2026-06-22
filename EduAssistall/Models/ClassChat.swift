import Foundation

// Phase 3: Teacher-moderated class chat system
struct ClassChatMessage: Codable, Identifiable {
    var id: String
    var studentId: String
    var studentName: String
    var message: String
    var timestamp: Date
    var approved: Bool
    var approvedBy: String? // Teacher ID who approved
    var approvedAt: Date?
    
    init(studentId: String, studentName: String, message: String) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.studentName = studentName
        self.message = message
        self.timestamp = Date()
        self.approved = false
        self.approvedBy = nil
        self.approvedAt = nil
    }
}

// Phase 3: Achievement sharing to parent feed
struct ParentAchievement: Codable, Identifiable {
    var id: String
    var studentId: String
    var studentName: String
    var achievementType: AchievementType
    var title: String
    var description: String
    var timestamp: Date
    var viewed: Bool
    
    enum AchievementType: String, Codable {
        case badge = "badge"
        case levelUp = "level_up"
        case streak = "streak"
        case pathComplete = "path_complete"
    }
    
    init(studentId: String, studentName: String, achievementType: AchievementType, title: String, description: String) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.studentName = studentName
        self.achievementType = achievementType
        self.title = title
        self.description = description
        self.timestamp = Date()
        self.viewed = false
    }
}

// Phase 3: Teacher spotlight
struct TeacherSpotlight: Codable, Identifiable {
    var id: String
    var teacherId: String
    var teacherName: String
    var studentId: String
    var studentName: String
    var reason: String
    var timestamp: Date
    var sharedWithParents: Bool
    
    init(teacherId: String, teacherName: String, studentId: String, studentName: String, reason: String) {
        self.id = UUID().uuidString
        self.teacherId = teacherId
        self.teacherName = teacherName
        self.studentId = studentId
        self.studentName = studentName
        self.reason = reason
        self.timestamp = Date()
        self.sharedWithParents = false
    }
}
