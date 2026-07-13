import Foundation

// Phase 5A: Tournament event
struct Tournament: Codable, Identifiable {
    var id: String
    var title: String
    var theme: String
    var description: String
    var tournamentType: TournamentType
    var startDate: Date
    var endDate: Date
    var rewardStructure: RewardStructure
    var participationRequirements: ParticipationRequirements
    var events: [TournamentEvent]
    var isActive: Bool
    var participantCount: Int
    var createdBy: String
    var createdAt: Date
    
    enum TournamentType: String, Codable, CaseIterable {
        case quiz = "quiz"
        case path = "path"
        case streak = "streak"
        case mixed = "mixed"
        
        var displayName: String {
            switch self {
            case .quiz: return "Quiz Tournament"
            case .path: return "Path Race Tournament"
            case .streak: return "Streak Tournament"
            case .mixed: return "Mixed Tournament"
            }
        }
        
        var icon: String {
            switch self {
            case .quiz: return "checkmark.square.fill"
            case .path: return "flag.fill"
            case .streak: return "flame.fill"
            case .mixed: return "star.fill"
            }
        }
    }
    
    struct RewardStructure: Codable {
        var xpReward: Int
        var badgeReward: BadgeType?
        var avatarReward: AvatarAccessory?
        var titleReward: String?
        var xpMultiplier: Double
        
        init(xpReward: Int = 500, badgeReward: BadgeType? = nil, avatarReward: AvatarAccessory? = nil, titleReward: String? = nil, xpMultiplier: Double = 1.0) {
            self.xpReward = xpReward
            self.badgeReward = badgeReward
            self.avatarReward = avatarReward
            self.titleReward = titleReward
            self.xpMultiplier = xpMultiplier
        }
    }
    
    struct ParticipationRequirements: Codable {
        var minimumLevel: Int
        var requiredBadges: [BadgeType]
        var minimumStreak: Int
        
        init(minimumLevel: Int = 1, requiredBadges: [BadgeType] = [], minimumStreak: Int = 0) {
            self.minimumLevel = minimumLevel
            self.requiredBadges = requiredBadges
            self.minimumStreak = minimumStreak
        }
    }
    
    struct TournamentEvent: Codable, Identifiable {
        var id: String
        var eventType: EventType
        var title: String
        var description: String
        var startDate: Date
        var endDate: Date
        var points: Int
        
        enum EventType: String, Codable {
            case quizChallenge = "quiz_challenge"
            case pathRace = "path_race"
            case streakChallenge = "streak_challenge"
        }
    }
    
    init(title: String, theme: String, description: String, tournamentType: TournamentType, startDate: Date, endDate: Date, createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.theme = theme
        self.description = description
        self.tournamentType = tournamentType
        self.startDate = startDate
        self.endDate = endDate
        self.rewardStructure = RewardStructure()
        self.participationRequirements = ParticipationRequirements()
        self.events = []
        self.isActive = true
        self.participantCount = 0
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

// Phase 5A: Student tournament participation
struct TournamentParticipation: Codable, Identifiable {
    var id: String
    var studentId: String
    var tournamentId: String
    var eventCompletions: [String: EventCompletion] // eventId -> completion data
    var totalPoints: Int
    var currentRank: Int
    var rewardsClaimed: Bool
    var joinedAt: Date
    var lastUpdatedAt: Date
    
    struct EventCompletion: Codable {
        var completed: Bool
        var score: Int
        var completedAt: Date?
        
        init(completed: Bool = false, score: Int = 0) {
            self.completed = completed
            self.score = score
            self.completedAt = nil
        }
    }
    
    init(studentId: String, tournamentId: String) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.tournamentId = tournamentId
        self.eventCompletions = [:]
        self.totalPoints = 0
        self.currentRank = 0
        self.rewardsClaimed = false
        self.joinedAt = Date()
        self.lastUpdatedAt = Date()
    }
    
    mutating func addEventCompletion(eventId: String, score: Int) {
        self.eventCompletions[eventId] = EventCompletion(completed: true, score: score, completedAt: Date())
        self.totalPoints += score
        self.lastUpdatedAt = Date()
    }
}
