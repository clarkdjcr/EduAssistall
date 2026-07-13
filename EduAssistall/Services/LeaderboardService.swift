import Foundation

// Phase 5A: Leaderboard management service
class LeaderboardService {
    static let shared = LeaderboardService()
    
    private init() {}
    
    // Fetch leaderboard entries based on configuration
    func fetchLeaderboard(config: LeaderboardConfig, classId: String? = nil) async throws -> [LeaderboardEntry] {
        // In production, this would query Firestore with proper indexes
        // For now, return empty array - will be populated by FirestoreService
        return []
    }
    
    // Calculate ranks for leaderboard entries
    func calculateRanks(entries: [LeaderboardEntry], category: LeaderboardConfig.Category) -> [LeaderboardEntry] {
        var rankedEntries = entries
        
        // Sort based on category
        switch category {
        case .xp:
            rankedEntries.sort { $0.xp > $1.xp }
        case .streak:
            rankedEntries.sort { $0.currentStreak > $1.currentStreak }
        case .badges:
            rankedEntries.sort { $0.badgeCount > $1.badgeCount }
        case .quests:
            rankedEntries.sort { $0.level > $1.level }
        }
        
        // Assign ranks
        for (index, _) in rankedEntries.enumerated() {
            rankedEntries[index].rank = index + 1
        }
        
        return rankedEntries
    }
    
    // Filter out students who opted out
    func filterOptOutEntries(entries: [LeaderboardEntry], optedOutIds: Set<String>) -> [LeaderboardEntry] {
        return entries.filter { !optedOutIds.contains($0.studentId) }
    }
    
    // Get user's rank in leaderboard
    func getUserRank(entries: [LeaderboardEntry], userId: String) -> Int? {
        return entries.first { $0.studentId == userId }?.rank
    }
    
    // Cache leaderboard data locally
    private var cachedLeaderboard: [String: [LeaderboardEntry]] = [:]
    private var cacheTimestamp: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    func getCachedLeaderboard(config: LeaderboardConfig) -> [LeaderboardEntry]? {
        let cacheKey = generateCacheKey(config: config)
        guard let timestamp = cacheTimestamp[cacheKey] else { return nil }
        
        if Date().timeIntervalSince(timestamp) < cacheValidityDuration {
            return cachedLeaderboard[cacheKey]
        }
        
        return nil
    }
    
    func cacheLeaderboard(entries: [LeaderboardEntry], config: LeaderboardConfig) {
        let cacheKey = generateCacheKey(config: config)
        cachedLeaderboard[cacheKey] = entries
        cacheTimestamp[cacheKey] = Date()
    }
    
    private func generateCacheKey(config: LeaderboardConfig) -> String {
        return "\(config.timePeriod.rawValue)_\(config.category.rawValue)_\(config.scope.rawValue)"
    }
}
