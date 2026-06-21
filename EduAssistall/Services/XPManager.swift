import Foundation
import SwiftUI

// Phase 2: XP calculation and level progression system
class XPManager {
    static let shared = XPManager()
    
    private init() {}
    
    // XP values for different actions
    struct XPValues {
        static let lessonCompletion = 100
        static let quizCompletion = 50
        static let perfectQuiz = 75
        static let streakDay = 25
        static let badgeEarned = 150
        static let pathComplete = 500
        static let levelUp = 200
        static let helpfulAnswer = 30
        static let questComplete = 300
    }
    
    // Level progression: 1000 XP per level
    static let xpPerLevel = 1000
    
    // Calculate XP required for a specific level
    static func xpRequired(forLevel level: Int) -> Int {
        return level * xpPerLevel
    }
    
    // Calculate current level from total XP
    static func levelFromXP(_ xp: Int) -> Int {
        return (xp / xpPerLevel) + 1
    }
    
    // Calculate XP progress within current level
    static func xpProgressInLevel(_ xp: Int) -> Double {
        let currentLevel = levelFromXP(xp)
        let xpForCurrentLevel = xpRequired(forLevel: currentLevel - 1)
        let xpForNextLevel = xpRequired(forLevel: currentLevel)
        let xpInCurrentLevel = xp - xpForCurrentLevel
        let xpNeededForLevel = xpForNextLevel - xpForCurrentLevel
        return Double(xpInCurrentLevel) / Double(xpNeededForLevel)
    }
    
    // Award XP for lesson completion
    static func awardLessonCompletion() -> Int {
        return XPValues.lessonCompletion
    }
    
    // Award XP for quiz completion
    static func awardQuizCompletion(score: Int, maxScore: Int) -> Int {
        let baseXP = XPValues.quizCompletion
        if score == maxScore {
            return baseXP + XPValues.perfectQuiz
        }
        let percentage = Double(score) / Double(maxScore)
        return Int(Double(baseXP) * percentage)
    }
    
    // Award XP for streak
    static func awardStreakXP(streakDays: Int) -> Int {
        // Bonus multiplier for longer streaks
        let multiplier = min(2.0, 1.0 + (Double(streakDays) * 0.05))
        return Int(Double(XPValues.streakDay) * multiplier)
    }
    
    // Award XP for badge
    static func awardBadgeXP(badgeRarity: BadgeRarity) -> Int {
        switch badgeRarity {
        case .common: return XPValues.badgeEarned
        case .rare: return Int(Double(XPValues.badgeEarned) * 1.5)
        case .epic: return Int(Double(XPValues.badgeEarned) * 2.0)
        case .legendary: return Int(Double(XPValues.badgeEarned) * 3.0)
        }
    }
    
    // Award XP for path completion
    static func awardPathCompletion() -> Int {
        return XPValues.pathComplete
    }
    
    // Award XP for helpful answer
    static func awardHelpfulAnswer() -> Int {
        return XPValues.helpfulAnswer
    }
    
    // Award XP for quest completion
    static func awardQuestCompletion() -> Int {
        return XPValues.questComplete
    }
    
    // Check if level up occurs
    static func checkLevelUp(currentXP: Int, xpToAdd: Int) -> Bool {
        let currentLevel = levelFromXP(currentXP)
        let newXP = currentXP + xpToAdd
        let newLevel = levelFromXP(newXP)
        return newLevel > currentLevel
    }
    
    // Get level up rewards
    static func getLevelUpRewards(forLevel level: Int) -> [AvatarAccessory] {
        var rewards: [AvatarAccessory] = []
        
        // Level-based unlocks
        switch level {
        case 2:
            rewards.append(.glasses)
        case 5:
            rewards.append(.hatBaseball)
        case 8:
            rewards.append(.hatBeanie)
        case 12:
            rewards.append(.headphones)
        case 15:
            rewards.append(.bowtie)
        default:
            break
        }
        
        return rewards
    }
}

// Phase 2: Level celebration view
struct LevelUpCelebrationView: View {
    let newLevel: Int
    let rewards: [AvatarAccessory]
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
                
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 80))
                    
                    Text("Level Up!")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("You reached Level \(newLevel)")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    if !rewards.isEmpty {
                        VStack(spacing: 12) {
                            Text("New Unlocks!")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            ForEach(rewards) { reward in
                                HStack(spacing: 12) {
                                    Image(systemName: reward.icon)
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                    Text(reward.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(32)
                .background(Color.blue.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            SoundEffectsManager.shared.playLevelUpSound()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}
