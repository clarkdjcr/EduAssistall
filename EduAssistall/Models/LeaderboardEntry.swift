import Foundation

// Phase 5A: Leaderboard entry structure
struct LeaderboardEntry: Codable, Identifiable {
    var id: String
    var studentId: String
    var studentName: String
    var xp: Int
    var level: Int
    var currentStreak: Int
    var badgeCount: Int
    var avatarConfig: AvatarConfig?
    var rank: Int
    var rankChange: RankChange
    var updatedAt: Date
    
    enum RankChange: String, Codable {
        case up = "up"
        case down = "down"
        case same = "same"
        case new = "new"
    }
    
    init(studentId: String, studentName: String, xp: Int, level: Int, currentStreak: Int, badgeCount: Int, avatarConfig: AvatarConfig? = nil) {
        self.id = UUID().uuidString
        self.studentId = studentId
        self.studentName = studentName
        self.xp = xp
        self.level = level
        self.currentStreak = currentStreak
        self.badgeCount = badgeCount
        self.avatarConfig = avatarConfig
        self.rank = 0
        self.rankChange = .new
        self.updatedAt = Date()
    }
}

// Phase 5A: Leaderboard configuration
struct LeaderboardConfig: Codable {
    var timePeriod: TimePeriod
    var category: Category
    var scope: Scope
    var privacyEnabled: Bool
    
    enum TimePeriod: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case allTime = "all_time"
        
        var displayName: String {
            switch self {
            case .daily: return "Today"
            case .weekly: return "This Week"
            case .monthly: return "This Month"
            case .allTime: return "All Time"
            }
        }
    }
    
    enum Category: String, Codable, CaseIterable {
        case xp = "xp"
        case streak = "streak"
        case badges = "badges"
        case quests = "quests"
        
        var displayName: String {
            switch self {
            case .xp: return "XP"
            case .streak: return "Streak"
            case .badges: return "Badges"
            case .quests: return "Quests"
            }
        }
        
        var icon: String {
            switch self {
            case .xp: return "star.fill"
            case .streak: return "flame.fill"
            case .badges: return "rosette"
            case .quests: return "flag.fill"
            }
        }
    }
    
    enum Scope: String, Codable, CaseIterable {
        case global = "global"
        case classScope = "class"
        
        var displayName: String {
            switch self {
            case .global: return "Global"
            case .classScope: return "Class"
            }
        }
    }
    
    init(timePeriod: TimePeriod = .weekly, category: Category = .xp, scope: Scope = .classScope, privacyEnabled: false) {
        self.timePeriod = timePeriod
        self.category = category
        self.scope = scope
        self.privacyEnabled = privacyEnabled
    }
}
