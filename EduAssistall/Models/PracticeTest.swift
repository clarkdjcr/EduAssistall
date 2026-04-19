import Foundation
import SwiftUI

// MARK: - Test Type

enum TestType: String, Codable, CaseIterable {
    case sat      = "SAT"
    case act      = "ACT"
    case state    = "State"
    case practice = "Practice"

    var displayName: String { rawValue }

    var color: Color {
        switch self {
        case .sat:      return .blue
        case .act:      return .purple
        case .state:    return .orange
        case .practice: return .green
        }
    }

    var icon: String {
        switch self {
        case .sat:      return "s.square.fill"
        case .act:      return "a.square.fill"
        case .state:    return "building.columns.fill"
        case .practice: return "pencil.and.list.clipboard"
        }
    }
}

// MARK: - Practice Test Question

struct PracticeTestQuestion: Codable, Identifiable {
    var id: String
    var question: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
    var standardCode: String?
    var subject: String
}

// MARK: - Practice Test

struct PracticeTest: Codable, Identifiable {
    var id: String
    var title: String
    var type: TestType
    var subject: String
    var gradeLevel: String
    var questions: [PracticeTestQuestion]
    var timeLimit: Int          // minutes
    var createdAt: Date
}

// MARK: - Test Attempt

struct TestAttempt: Codable, Identifiable {
    var id: String
    var studentId: String
    var testId: String
    var testTitle: String
    var testType: String
    var answers: [Int]          // selected index per question (-1 = unanswered)
    var score: Int              // 0–100
    var correctCount: Int
    var totalCount: Int
    var timeTakenSeconds: Int
    var completedAt: Date

    init(studentId: String, test: PracticeTest, answers: [Int], timeTakenSeconds: Int) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.testId = test.id
        self.testTitle = test.title
        self.testType = test.type.rawValue
        self.answers = answers
        let correct = zip(answers, test.questions).filter { $0.0 == $0.1.correctIndex }.count
        self.correctCount = correct
        self.totalCount = test.questions.count
        self.score = test.questions.isEmpty ? 0 : Int(Double(correct) / Double(test.questions.count) * 100)
        self.timeTakenSeconds = timeTakenSeconds
        self.completedAt = Date()
    }
}
