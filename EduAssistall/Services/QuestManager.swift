import Foundation

// Phase 4: Quest management system
class QuestManager {
    static let shared = QuestManager()
    
    private init() {}
    
    // Generate weekly quests for a student
    static func generateWeeklyQuests(studentId: String, learningProfile: LearningProfile?) -> [Quest] {
        var quests: [Quest] = []
        
        // Learning quest based on interests
        if let interests = learningProfile?.interests, !interests.isEmpty {
            let interest = interests.randomElement() ?? "learning"
            quests.append(Quest(
                title: "Interest Explorer",
                description: "Complete 5 lessons related to \(interest)",
                tasks: [
                    QuestTask(description: "Complete 5 lessons", taskType: .completeLessons, targetValue: 5)
                ],
                xpReward: 300,
                difficulty: .medium,
                category: .learning
            ))
        }
        
        // Social quest
        quests.append(Quest(
            title: "Helpful Classmate",
            description: "Give kudos to 3 classmates",
            tasks: [
                QuestTask(description: "Give 3 kudos", taskType: .giveKudos, targetValue: 3)
            ],
            xpReward: 150,
            difficulty: .easy,
            category: .social
        ))
        
        // Streak quest
        quests.append(Quest(
            title: "Streak Master",
            description: "Maintain a 7-day learning streak",
            tasks: [
                QuestTask(description: "7-day streak", taskType: .maintainStreak, targetValue: 7)
            ],
            xpReward: 250,
            difficulty: .medium,
            category: .challenge
        ))
        
        // Badge quest
        quests.append(Quest(
            title: "Badge Collector",
            description: "Earn 3 new badges",
            tasks: [
                QuestTask(description: "Earn 3 badges", taskType: .earnBadges, targetValue: 3)
            ],
            xpReward: 200,
            difficulty: .medium,
            category: .exploration
        ))
        
        // Challenge quest
        quests.append(Quest(
            title: "Quiz Champion",
            description: "Complete 5 quizzes with 80%+ score",
            tasks: [
                QuestTask(description: "Complete 5 quizzes", taskType: .completeQuizzes, targetValue: 5)
            ],
            xpReward: 400,
            difficulty: .hard,
            category: .challenge
        ))
        
        return quests
    }
    
    // Calculate quest progress
    static func calculateProgress(quest: Quest, progress: QuestProgress) -> Double {
        guard !quest.tasks.isEmpty else { return 0 }
        
        var completedTasks = 0
        for task in quest.tasks {
            let currentValue = progress.taskProgress[task.id] ?? 0
            if currentValue >= task.targetValue {
                completedTasks += 1
            }
        }
        
        return Double(completedTasks) / Double(quest.tasks.count)
    }
    
    // Check if quest is complete
    static func isQuestComplete(quest: Quest, progress: QuestProgress) -> Bool {
        for task in quest.tasks {
            let currentValue = progress.taskProgress[task.id] ?? 0
            if currentValue < task.targetValue {
                return false
            }
        }
        return true
    }
    
    // Award quest rewards
    static func awardQuestRewards(quest: Quest, studentId: String) async throws {
        // Award XP
        try? await FirestoreService.shared.awardXP(studentId: studentId, xpAmount: quest.xpReward)
        
        // Award badge if applicable
        if let badgeType = quest.badgeReward {
            try? await FirestoreService.shared.awardBadge(studentId: studentId, type: badgeType)
        }
    }
}

// Phase 4: Content recommendation engine
class RecommendationEngine {
    static let shared = RecommendationEngine()
    
    private init() {}
    
    // Generate recommendations based on learning profile
    static func generateRecommendations(
        studentId: String,
        learningProfile: LearningProfile?,
        completedPaths: [LearningPath],
        allPaths: [LearningPath]
    ) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Recommend based on interests
        if let interests = learningProfile?.interests, !interests.isEmpty {
            for interest in interests {
                // Find paths related to interest
                let relatedPaths = allPaths.filter { path in
                    path.title.lowercased().contains(interest.lowercased()) ||
                    path.description.lowercased().contains(interest.lowercased())
                }
                
                for path in relatedPaths.prefix(2) {
                    let alreadyCompleted = completedPaths.contains { $0.id == path.id }
                    if !alreadyCompleted {
                        recommendations.append(ContentRecommendation(
                            studentId: studentId,
                            contentItemId: path.id,
                            contentTitle: path.title,
                            reason: "Based on your interest in \(interest)",
                            relevanceScore: 0.8
                        ))
                    }
                }
            }
        }
        
        // Recommend based on learning style
        if let style = learningProfile?.learningStyle {
            let styleRecommendations = allPaths.filter { path in
                // Simple heuristic - in production would use ML
                switch style {
                case .visual:
                    return path.title.contains("Visual") || path.title.contains("Diagram")
                case .auditory:
                    return path.title.contains("Audio") || path.title.contains("Listen")
                case .kinesthetic:
                    return path.title.contains("Hands-on") || path.title.contains("Practice")
                case .readWrite:
                    return path.title.contains("Reading") || path.title.contains("Writing")
                }
            }
            
            for path in styleRecommendations.prefix(2) {
                let alreadyCompleted = completedPaths.contains { $0.id == path.id }
                if !alreadyCompleted {
                    recommendations.append(ContentRecommendation(
                        studentId: studentId,
                        contentItemId: path.id,
                        contentTitle: path.title,
                        reason: "Matches your \(style.displayName) learning style",
                        relevanceScore: 0.7
                    ))
                }
            }
        }
        
        // Recommend popular paths
        let popularPaths = allPaths.shuffled().prefix(3)
        for path in popularPaths {
            let alreadyCompleted = completedPaths.contains { $0.id == path.id }
            let alreadyRecommended = recommendations.contains { $0.contentItemId == path.id }
            if !alreadyCompleted && !alreadyRecommended {
                recommendations.append(ContentRecommendation(
                    studentId: studentId,
                    contentItemId: path.id,
                    contentTitle: path.title,
                    reason: "Popular with other students",
                    relevanceScore: 0.5
                ))
            }
        }
        
        // Sort by relevance and limit
        return recommendations
            .sorted { $0.relevanceScore > $1.relevanceScore }
            .prefix(5)
            .map { $0 }
    }
}
