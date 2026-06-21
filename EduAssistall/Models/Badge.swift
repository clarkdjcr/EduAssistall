import Foundation
import SwiftUI

// Phase 1: Badge rarity tiers
enum BadgeRarity: String, Codable, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        }
    }
    
    var glowIntensity: Double {
        switch self {
        case .common: return 0.0
        case .rare: return 0.3
        case .epic: return 0.6
        case .legendary: return 1.0
        }
    }
}

enum BadgeType: String, Codable, CaseIterable {
    // Original badges
    case firstLesson  = "first_lesson"
    case pathComplete = "path_complete"
    case perfectQuiz  = "perfect_quiz"
    case allSubjects  = "all_subjects"
    
    // Phase 1: Streak achievements
    case streak3 = "streak_3"
    case streak7 = "streak_7"
    case streak30 = "streak_30"
    
    // Phase 1: Speed challenges
    case speedDemon = "speed_demon"
    case quickLearner = "quick_learner"
    
    // Phase 1: Subject mastery
    case mathMaster = "math_master"
    case scienceMaster = "science_master"
    case elaMaster = "ela_master"
    
    // Phase 1: Helper badges
    case helpfulAnswer = "helpful_answer"
    case mentor = "mentor"

    var title: String {
        switch self {
        case .firstLesson:  return "First Step"
        case .pathComplete: return "Path Finisher"
        case .perfectQuiz:  return "Quiz Master"
        case .allSubjects:  return "Renaissance Learner"
        case .streak3: return "3-Day Streak"
        case .streak7: return "Week Warrior"
        case .streak30: return "Monthly Master"
        case .speedDemon: return "Speed Demon"
        case .quickLearner: return "Quick Learner"
        case .mathMaster: return "Math Master"
        case .scienceMaster: return "Science Master"
        case .elaMaster: return "ELA Master"
        case .helpfulAnswer: return "Helpful Answer"
        case .mentor: return "Mentor"
        }
    }

    var description: String {
        switch self {
        case .firstLesson:  return "Completed your first lesson"
        case .pathComplete: return "Finished an entire learning path"
        case .perfectQuiz:  return "Scored 100% on a quiz"
        case .allSubjects:  return "Completed lessons in 3+ subjects"
        case .streak3: return "Maintained a 3-day learning streak"
        case .streak7: return "Maintained a 7-day learning streak"
        case .streak30: return "Maintained a 30-day learning streak"
        case .speedDemon: return "Completed a quiz in under 2 minutes"
        case .quickLearner: return "Completed 5 lessons in one day"
        case .mathMaster: return "Completed 10 math lessons"
        case .scienceMaster: return "Completed 10 science lessons"
        case .elaMaster: return "Completed 10 ELA lessons"
        case .helpfulAnswer: return "Received 5 kudos for helpful answers"
        case .mentor: return "Received 20 kudos for helpful answers"
        }
    }

    var icon: String {
        switch self {
        case .firstLesson:  return "star.fill"
        case .pathComplete: return "flag.checkered"
        case .perfectQuiz:  return "rosette"
        case .allSubjects:  return "sparkles"
        case .streak3: return "flame.fill"
        case .streak7: return "fire.fill"
        case .streak30: return "flame.circle.fill"
        case .speedDemon: return "bolt.fill"
        case .quickLearner: return "hare.fill"
        case .mathMaster: return "function"
        case .scienceMaster: return "atom"
        case .elaMaster: return "book.fill"
        case .helpfulAnswer: return "hand.thumbsup.fill"
        case .mentor: return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstLesson:  return .yellow
        case .pathComplete: return .green
        case .perfectQuiz:  return .purple
        case .allSubjects:  return .blue
        case .streak3: return .orange
        case .streak7: return .red
        case .streak30: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .speedDemon: return .cyan
        case .quickLearner: return .mint
        case .mathMaster: return .indigo
        case .scienceMaster: return .teal
        case .elaMaster: return .brown
        case .helpfulAnswer: return .pink
        case .mentor: return Color(red: 0.8, green: 0.4, blue: 0.8)
        }
    }
    
    var rarity: BadgeRarity {
        switch self {
        case .firstLesson, .streak3, .helpfulAnswer: return .common
        case .pathComplete, .perfectQuiz, .streak7, .speedDemon, .quickLearner, .mathMaster, .scienceMaster, .elaMaster: return .rare
        case .allSubjects, .streak30, .mentor: return .epic
        }
    }
}

struct Badge: Codable, Identifiable {
    var id: String        // = badgeType.rawValue
    var badgeType: BadgeType
    var earnedAt: Date
}
