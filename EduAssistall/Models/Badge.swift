import Foundation
import SwiftUI

enum BadgeType: String, Codable, CaseIterable {
    case firstLesson  = "first_lesson"
    case pathComplete = "path_complete"
    case perfectQuiz  = "perfect_quiz"
    case allSubjects  = "all_subjects"

    var title: String {
        switch self {
        case .firstLesson:  return "First Step"
        case .pathComplete: return "Path Finisher"
        case .perfectQuiz:  return "Quiz Master"
        case .allSubjects:  return "Renaissance Learner"
        }
    }

    var description: String {
        switch self {
        case .firstLesson:  return "Completed your first lesson"
        case .pathComplete: return "Finished an entire learning path"
        case .perfectQuiz:  return "Scored 100% on a quiz"
        case .allSubjects:  return "Completed lessons in 3+ subjects"
        }
    }

    var icon: String {
        switch self {
        case .firstLesson:  return "star.fill"
        case .pathComplete: return "flag.checkered"
        case .perfectQuiz:  return "rosette"
        case .allSubjects:  return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .firstLesson:  return .yellow
        case .pathComplete: return .green
        case .perfectQuiz:  return .purple
        case .allSubjects:  return .blue
        }
    }
}

struct Badge: Codable, Identifiable {
    var id: String        // = badgeType.rawValue
    var badgeType: BadgeType
    var earnedAt: Date
}
