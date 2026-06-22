import Foundation
import SwiftUI

// Phase 4: Quest system
struct Quest: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var tasks: [QuestTask]
    var xpReward: Int
    var badgeReward: BadgeType?
    var difficulty: QuestDifficulty
    var category: QuestCategory
    var isActive: Bool
    var startDate: Date
    var endDate: Date?
    
    enum QuestDifficulty: String, Codable, CaseIterable {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
        
        var displayName: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .yellow
            case .hard: return .red
            }
        }
    }
    
    enum QuestCategory: String, Codable, CaseIterable {
        case learning = "learning"
        case social = "social"
        case exploration = "exploration"
        case challenge = "challenge"
        
        var displayName: String {
            switch self {
            case .learning: return "Learning"
            case .social: return "Social"
            case .exploration: return "Exploration"
            case .challenge: return "Challenge"
            }
        }
        
        var icon: String {
            switch self {
            case .learning: return "book.fill"
            case .social: return "person.2.fill"
            case .exploration: return "compass.fill"
            case .challenge: return "trophy.fill"
            }
        }
    }
    
    init(title: String, description: String, tasks: [QuestTask], xpReward: Int, difficulty: QuestDifficulty, category: QuestCategory) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.tasks = tasks
        self.xpReward = xpReward
        self.badgeReward = nil
        self.difficulty = difficulty
        self.category = category
        self.isActive = true
        self.startDate = Date()
        self.endDate = nil
    }
}

struct QuestTask: Codable, Identifiable {
    var id: String
    var description: String
    var taskType: QuestTaskType
    var targetValue: Int
    var currentValue: Int
    var isCompleted: Bool
    
    enum QuestTaskType: String, Codable, CaseIterable {
        case completeLessons = "complete_lessons"
        case completeQuizzes = "complete_quizzes"
        case earnBadges = "earn_badges"
        case giveKudos = "give_kudos"
        case maintainStreak = "maintain_streak"
        case completePath = "complete_path"
        case reachLevel = "reach_level"
        
        var displayName: String {
            switch self {
            case .completeLessons: return "Complete Lessons"
            case .completeQuizzes: return "Complete Quizzes"
            case .earnBadges: return "Earn Badges"
            case .giveKudos: return "Give Kudos"
            case .maintainStreak: return "Maintain Streak"
            case .completePath: return "Complete Path"
            case .reachLevel: return "Reach Level"
            }
        }
    }
    
    init(description: String, taskType: QuestTaskType, targetValue: Int) {
        self.id = UUID().uuidString
        self.description = description
        self.taskType = taskType
        self.targetValue = targetValue
        self.currentValue = 0
        self.isCompleted = false
    }
}

struct QuestProgress: Codable, Identifiable {
    var id: String
    var questId: String
    var studentId: String
    var taskProgress: [String: Int] // taskId -> currentValue
    var isCompleted: Bool
    var completedAt: Date?
    var startedAt: Date
    
    init(questId: String, studentId: String) {
        self.id = UUID().uuidString
        self.questId = questId
        self.studentId = studentId
        self.taskProgress = [:]
        self.isCompleted = false
        self.completedAt = nil
        self.startedAt = Date()
    }
}

// Phase 4: Content recommendation
struct ContentRecommendation: Codable, Identifiable {
    var id: String
    var studentId: String
    var contentItemId: String
    var contentTitle: String
    var reason: String
    var relevanceScore: Double
    var timestamp: Date
    var isViewed: Bool
    
    init(studentId: String, contentItemId: String, contentTitle: String, reason: String, relevanceScore: Double) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.contentItemId = contentItemId
        self.contentTitle = contentTitle
        self.reason = reason
        self.relevanceScore = relevanceScore
        self.timestamp = Date()
        self.isViewed = false
    }
}
