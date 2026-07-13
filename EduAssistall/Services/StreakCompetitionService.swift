import Foundation

// Phase 5A: Streak competition management service
class StreakCompetitionService {
    static let shared = StreakCompetitionService()
    
    private init() {}
    
    // Create streak competition
    func createStreakCompetition(title: String, description: String, durationDays: Int, streakTarget: Int, startDate: Date, createdBy: String) -> StreakCompetition {
        return StreakCompetition(title: title, description: description, durationDays: durationDays, streakTarget: streakTarget, startDate: startDate, createdBy: createdBy)
    }
    
    // Track daily streak updates
    func updateStreak(studentId: String, competitionId: String, newStreak: Int, daysRemaining: Int) -> StreakCompetitionEntry {
        var entry = StreakCompetitionEntry(studentId: studentId, competitionId: competitionId, daysRemaining: daysRemaining)
        entry.updateStreak(newStreak: newStreak)
        
        // Check if target reached
        if newStreak >= entry.currentStreak {
            entry.targetReached = true
            entry.targetReachedAt = Date()
        }
        
        return entry
    }
    
    // Calculate competition standings
    func calculateStandings(entries: [StreakCompetitionEntry]) -> [StreakCompetitionEntry] {
        var rankedEntries = entries
        // Sort by best streak, then by current streak
        rankedEntries.sort {
            if $0.bestStreak != $1.bestStreak {
                return $0.bestStreak > $1.bestStreak
            }
            return $0.currentStreak > $1.currentStreak
        }
        
        for (index, _) in rankedEntries.enumerated() {
            rankedEntries[index].currentRank = index + 1
        }
        
        return rankedEntries
    }
    
    // Award bonus multipliers
    func applyBonusMultiplier(baseXP: Int, competition: StreakCompetition) -> Int {
        return Int(Double(baseXP) * competition.bonusMultiplier)
    }
    
    // Award competition rewards
    func awardCompetitionRewards(entry: StreakCompetitionEntry, competition: StreakCompetition) async throws {
        // Award XP
        let xpReward = competition.rewardStructure.xpReward
        // try? await FirestoreService.shared.awardXP(studentId: entry.studentId, xpAmount: xpReward)
        
        // Award badge if applicable
        if let badgeType = competition.rewardStructure.badgeReward {
            // try? await FirestoreService.shared.awardBadge(studentId: entry.studentId, type: badgeType)
        }
        
        // Award streak freezes
        if competition.rewardStructure.streakFreezeReward > 0 {
            // try? await FirestoreService.shared.updateStreakFreezes(studentId: entry.studentId, count: competition.rewardStructure.streakFreezeReward)
        }
    }
    
    // Generate competition leaderboard
    func generateCompetitionLeaderboard(competitionId: String) async throws -> [StreakCompetitionEntry] {
        // In production, this would query Firestore
        return []
    }
}
