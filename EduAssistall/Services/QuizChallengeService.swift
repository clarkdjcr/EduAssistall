import Foundation

// Phase 5A: Quiz challenge management service
class QuizChallengeService {
    static let shared = QuizChallengeService()
    
    private init() {}
    
    // Create weekly quiz challenge
    func createWeeklyChallenge(title: String, theme: String, description: String, startDate: Date, endDate: Date, createdBy: String) -> QuizChallenge {
        return QuizChallenge(title: title, theme: theme, description: description, startDate: startDate, endDate: endDate, createdBy: createdBy)
    }
    
    // Track student participation in challenge
    func trackParticipation(studentId: String, challengeId: String, quizId: String, score: Int, correctCount: Int, totalCount: Int) -> QuizChallengeEntry {
        // In production, this would fetch existing entry or create new one
        let entry = QuizChallengeEntry(studentId: studentId, challengeId: challengeId)
        let attempt = QuizChallengeEntry.QuizAttemptRecord(quizId: quizId, score: score, correctCount: correctCount, totalCount: totalCount)
        
        // Update best score
        if score > entry.bestScore {
            entry.bestScore = score
        }
        
        return entry
    }
    
    // Calculate challenge rankings
    func calculateChallengeRankings(entries: [QuizChallengeEntry]) -> [QuizChallengeEntry] {
        var rankedEntries = entries
        rankedEntries.sort { $0.bestScore > $1.bestScore }
        
        for (index, _) in rankedEntries.enumerated() {
            rankedEntries[index].rank = index + 1
        }
        
        return rankedEntries
    }
    
    // Award challenge rewards
    func awardChallengeRewards(entry: QuizChallengeEntry, challenge: QuizChallenge) async throws {
        // Award XP
        let xpReward = challenge.rewardStructure.xpReward
        // try? await FirestoreService.shared.awardXP(studentId: entry.studentId, xpAmount: xpReward)
        
        // Award badge if applicable
        if let badgeType = challenge.rewardStructure.badgeReward {
            // try? await FirestoreService.shared.awardBadge(studentId: entry.studentId, type: badgeType)
        }
        
        // Award streak freezes
        if challenge.rewardStructure.streakFreezeReward > 0 {
            // try? await FirestoreService.shared.updateStreakFreezes(studentId: entry.studentId, count: challenge.rewardStructure.streakFreezeReward)
        }
    }
    
    // Generate challenge leaderboard
    func generateChallengeLeaderboard(challengeId: String) async throws -> [QuizChallengeEntry] {
        // In production, this would query Firestore
        return []
    }
}
