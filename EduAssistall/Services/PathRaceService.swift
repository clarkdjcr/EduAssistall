import Foundation

// Phase 5A: Path race management service
class PathRaceService {
    static let shared = PathRaceService()
    
    private init() {}
    
    // Create path race
    func createPathRace(title: String, description: String, learningPathId: String, learningPathTitle: String, startDate: Date, endDate: Date, createdBy: String) -> PathRace {
        return PathRace(title: title, description: description, learningPathId: learningPathId, learningPathTitle: learningPathTitle, startDate: startDate, endDate: endDate, createdBy: createdBy)
    }
    
    // Track real-time progress
    func trackProgress(studentId: String, raceId: String, completionPercent: Int, itemsCompleted: Int, totalItems: Int) -> PathRaceProgress {
        var progress = PathRaceProgress(studentId: studentId, raceId: raceId, totalItems: totalItems)
        progress.updateProgress(completionPercent: completionPercent, itemsCompleted: itemsCompleted)
        return progress
    }
    
    // Calculate race rankings
    func calculateRaceRankings(progressEntries: [PathRaceProgress]) -> [PathRaceProgress] {
        var rankedEntries = progressEntries
        // Sort by completion percent, then by items completed, then by time
        rankedEntries.sort {
            if $0.pathCompletionPercent != $1.pathCompletionPercent {
                return $0.pathCompletionPercent > $1.pathCompletionPercent
            }
            if $0.itemsCompleted != $1.itemsCompleted {
                return $0.itemsCompleted > $1.itemsCompleted
            }
            return $0.timeElapsed < $1.timeElapsed
        }
        
        for (index, _) in rankedEntries.enumerated() {
            rankedEntries[index].currentRank = index + 1
        }
        
        return rankedEntries
    }
    
    // Determine race winner
    func determineWinner(race: PathRace, progressEntries: [PathRaceProgress]) -> String? {
        let ranked = calculateRaceRankings(progressEntries: progressEntries)
        return ranked.first?.studentId
    }
    
    // Award race rewards
    func awardRaceRewards(progress: PathRaceProgress, race: PathRace) async throws {
        // Award XP
        let xpReward = race.rewardStructure.xpReward
        // try? await FirestoreService.shared.awardXP(studentId: progress.studentId, xpAmount: xpReward)
        
        // Award badge if applicable
        if let badgeType = race.rewardStructure.badgeReward {
            // try? await FirestoreService.shared.awardBadge(studentId: progress.studentId, type: badgeType)
        }
        
        // Award avatar item if applicable
        if let avatarReward = race.rewardStructure.avatarReward {
            // Store in user's unlocked items
        }
    }
}
