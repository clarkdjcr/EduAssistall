import Foundation

// Phase 5A: Streak competition event
struct StreakCompetition: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var durationDays: Int
    var streakTarget: Int
    var startDate: Date
    var endDate: Date
    var participantIds: [String]
    var bonusMultiplier: Double
    var isActive: Bool
    var rewardStructure: RewardStructure
    var createdBy: String
    var createdAt: Date
    
    struct RewardStructure: Codable {
        var xpReward: Int
        var badgeReward: BadgeType?
        var streakFreezeReward: Int
        
        init(xpReward: Int = 250, badgeReward: BadgeType? = nil, streakFreezeReward: Int = 1) {
            self.xpReward = xpReward
            self.badgeReward = badgeReward
            self.streakFreezeReward = streakFreezeReward
        }
    }
    
    init(title: String, description: String, durationDays: Int, streakTarget: Int, startDate: Date, createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.durationDays = durationDays
        self.streakTarget = streakTarget
        self.startDate = startDate
        let calendar = Calendar.current
        self.endDate = calendar.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
        self.participantIds = []
        self.bonusMultiplier = 1.5
        self.isActive = true
        self.rewardStructure = RewardStructure()
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

// Phase 5A: Individual streak participation
struct StreakCompetitionEntry: Codable, Identifiable {
    var id: String
    var studentId: String
    var competitionId: String
    var currentStreak: Int
    var bestStreak: Int
    var daysRemaining: Int
    var targetReached: Bool
    var targetReachedAt: Date?
    var currentRank: Int
    var rewardsClaimed: Bool
    var joinedAt: Date
    var lastUpdatedAt: Date
    
    init(studentId: String, competitionId: String, daysRemaining: Int) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.competitionId = competitionId
        self.currentStreak = 0
        self.bestStreak = 0
        self.daysRemaining = daysRemaining
        self.targetReached = false
        self.targetReachedAt = nil
        self.currentRank = 0
        self.rewardsClaimed = false
        self.joinedAt = Date()
        self.lastUpdatedAt = Date()
    }
    
    mutating func updateStreak(newStreak: Int) {
        self.currentStreak = newStreak
        if newStreak > self.bestStreak {
            self.bestStreak = newStreak
        }
        self.lastUpdatedAt = Date()
    }
}
