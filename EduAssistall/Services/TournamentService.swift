import Foundation

// Phase 5A: Tournament management service
class TournamentService {
    static let shared = TournamentService()
    
    private init() {}
    
    // Create tournament
    func createTournament(title: String, theme: String, description: String, tournamentType: Tournament.TournamentType, startDate: Date, endDate: Date, createdBy: String) -> Tournament {
        return Tournament(title: title, theme: theme, description: description, tournamentType: tournamentType, startDate: startDate, endDate: endDate, createdBy: createdBy)
    }
    
    // Manage tournament events
    func addTournamentEvent(tournament: Tournament, eventType: Tournament.TournamentEvent.EventType, title: String, description: String, startDate: Date, endDate: Date, points: Int) -> Tournament {
        var updatedTournament = tournament
        let event = Tournament.TournamentEvent(id: UUID().uuidString, eventType: eventType, title: title, description: description, startDate: startDate, endDate: endDate, points: points)
        updatedTournament.events.append(event)
        return updatedTournament
    }
    
    // Track participation
    func trackParticipation(studentId: String, tournamentId: String) -> TournamentParticipation {
        return TournamentParticipation(studentId: studentId, tournamentId: tournamentId)
    }
    
    // Add event completion
    func addEventCompletion(participation: TournamentParticipation, eventId: String, score: Int) -> TournamentParticipation {
        var updatedParticipation = participation
        updatedParticipation.addEventCompletion(eventId: eventId, score: score)
        return updatedParticipation
    }
    
    // Calculate tournament standings
    func calculateTournamentStandings(participations: [TournamentParticipation]) -> [TournamentParticipation] {
        var rankedParticipations = participations
        rankedParticipations.sort { $0.totalPoints > $1.totalPoints }
        
        for (index, _) in rankedParticipations.enumerated() {
            rankedParticipations[index].currentRank = index + 1
        }
        
        return rankedParticipations
    }
    
    // Award tournament rewards
    func awardTournamentRewards(participation: TournamentParticipation, tournament: Tournament) async throws {
        // Award XP with multiplier
        let baseXP = tournament.rewardStructure.xpReward
        let xpReward = Int(Double(baseXP) * tournament.rewardStructure.xpMultiplier)
        // try? await FirestoreService.shared.awardXP(studentId: participation.studentId, xpAmount: xpReward)
        
        // Award badge if applicable
        if let badgeType = tournament.rewardStructure.badgeReward {
            // try? await FirestoreService.shared.awardBadge(studentId: participation.studentId, type: badgeType)
        }
        
        // Award avatar item if applicable
        if let avatarReward = tournament.rewardStructure.avatarReward {
            // Store in user's unlocked items
        }
        
        // Award title if applicable
        if let titleReward = tournament.rewardStructure.titleReward {
            // Store in user profile
        }
    }
    
    // Generate tournament leaderboard
    func generateTournamentLeaderboard(tournamentId: String) async throws -> [TournamentParticipation] {
        // In production, this would query Firestore
        return []
    }
    
    // Check participation requirements
    func meetsRequirements(studentId: String, tournament: Tournament) -> Bool {
        // In production, this would check student's level, badges, and streak
        return true
    }
}
