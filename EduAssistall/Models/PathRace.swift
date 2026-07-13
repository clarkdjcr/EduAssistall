import Foundation

// Phase 5A: Learning path race event
struct PathRace: Codable, Identifiable {
    var id: String
    var title: String
    var description: String
    var learningPathId: String
    var learningPathTitle: String
    var startDate: Date
    var endDate: Date
    var participantIds: [String]
    var winnerId: String?
    var winnerDeterminedAt: Date?
    var isActive: Bool
    var rewardStructure: RewardStructure
    var createdBy: String
    var createdAt: Date
    
    struct RewardStructure: Codable {
        var xpReward: Int
        var badgeReward: BadgeType?
        var avatarReward: AvatarAccessory?
        
        init(xpReward: Int = 300, badgeReward: BadgeType? = nil, avatarReward: AvatarAccessory? = nil) {
            self.xpReward = xpReward
            self.badgeReward = badgeReward
            self.avatarReward = avatarReward
        }
    }
    
    init(title: String, description: String, learningPathId: String, learningPathTitle: String, startDate: Date, endDate: Date, createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.learningPathId = learningPathId
        self.learningPathTitle = learningPathTitle
        self.startDate = startDate
        self.endDate = endDate
        self.participantIds = []
        self.winnerId = nil
        self.winnerDeterminedAt = nil
        self.isActive = true
        self.rewardStructure = RewardStructure()
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

// Phase 5A: Individual race progress
struct PathRaceProgress: Codable, Identifiable {
    var id: String
    var studentId: String
    var raceId: String
    var pathCompletionPercent: Int
    var itemsCompleted: Int
    var totalItems: Int
    var timeElapsed: TimeInterval
    var lastProgressUpdate: Date
    var currentRank: Int
    var rewardsClaimed: Bool
    
    init(studentId: String, raceId: String, totalItems: Int = 0) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.raceId = raceId
        self.pathCompletionPercent = 0
        self.itemsCompleted = 0
        self.totalItems = totalItems
        self.timeElapsed = 0
        self.lastProgressUpdate = Date()
        self.currentRank = 0
        self.rewardsClaimed = false
    }
    
    mutating func updateProgress(completionPercent: Int, itemsCompleted: Int) {
        self.pathCompletionPercent = completionPercent
        self.itemsCompleted = itemsCompleted
        self.lastProgressUpdate = Date()
    }
}
