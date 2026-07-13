import Foundation

// Phase 5A: Weekly quiz challenge
struct QuizChallenge: Codable, Identifiable {
    var id: String
    var title: String
    var theme: String
    var description: String
    var startDate: Date
    var endDate: Date
    var requiredQuizTypes: [String]
    var scoringRules: ScoringRules
    var rewardStructure: RewardStructure
    var participationCount: Int
    var isActive: Bool
    var createdBy: String
    var createdAt: Date
    
    struct ScoringRules: Codable {
        var pointsPerCorrectAnswer: Int
        var timeBonusMultiplier: Double
        var streakBonusMultiplier: Double
        var perfectQuizBonus: Int
        
        init(pointsPerCorrectAnswer: Int = 10, timeBonusMultiplier: Double = 1.0, streakBonusMultiplier: Double = 1.0, perfectQuizBonus: Int = 50) {
            self.pointsPerCorrectAnswer = pointsPerCorrectAnswer
            self.timeBonusMultiplier = timeBonusMultiplier
            self.streakBonusMultiplier = streakBonusMultiplier
            self.perfectQuizBonus = perfectQuizBonus
        }
    }
    
    struct RewardStructure: Codable {
        var xpReward: Int
        var badgeReward: BadgeType?
        var streakFreezeReward: Int
        
        init(xpReward: Int = 200, badgeReward: BadgeType? = nil, streakFreezeReward: Int = 0) {
            self.xpReward = xpReward
            self.badgeReward = badgeReward
            self.streakFreezeReward = streakFreezeReward
        }
    }
    
    init(title: String, theme: String, description: String, startDate: Date, endDate: Date, createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.theme = theme
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.requiredQuizTypes = []
        self.scoringRules = ScoringRules()
        self.rewardStructure = RewardStructure()
        self.participationCount = 0
        self.isActive = true
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

// Phase 5A: Student challenge participation
struct QuizChallengeEntry: Codable, Identifiable {
    var id: String
    var studentId: String
    var challengeId: String
    var quizAttempts: [QuizAttemptRecord]
    var bestScore: Int
    var completionTime: TimeInterval?
    var rank: Int
    var rewardsClaimed: Bool
    var joinedAt: Date
    var lastUpdatedAt: Date
    
    struct QuizAttemptRecord: Codable, Identifiable {
        var id: String
        var quizId: String
        var score: Int
        var correctCount: Int
        var totalCount: Int
        var completedAt: Date
        
        init(quizId: String, score: Int, correctCount: Int, totalCount: Int) {
            self.id = UUID().uuidString
            self.quizId = quizId
            self.score = score
            self.correctCount = correctCount
            self.totalCount = totalCount
            self.completedAt = Date()
        }
    }
    
    init(studentId: String, challengeId: String) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.challengeId = challengeId
        self.quizAttempts = []
        self.bestScore = 0
        self.completionTime = nil
        self.rank = 0
        self.rewardsClaimed = false
        self.joinedAt = Date()
        self.lastUpdatedAt = Date()
    }
}
