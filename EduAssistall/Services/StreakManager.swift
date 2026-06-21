import Foundation
import SwiftUI

// Phase 1: Streak management with freeze items and celebrations
class StreakManager {
    static let shared = StreakManager()
    
    private init() {}
    
    // Award streak freeze (1 per week, max 3 stored)
    static func awardStreakFreeze(profile: UserProfile) -> UserProfile {
        var updatedProfile = profile
        // Max 3 streak freezes can be stored
        if updatedProfile.streakFreezes < 3 {
            updatedProfile.streakFreezes += 1
        }
        return updatedProfile
    }
    
    // Use streak freeze to protect streak
    static func useStreakFreeze(profile: UserProfile) -> UserProfile {
        var updatedProfile = profile
        if updatedProfile.streakFreezes > 0 {
            updatedProfile.streakFreezes -= 1
        }
        return updatedProfile
    }
    
    // Check if streak milestone celebration should trigger
    static func shouldCelebrateStreak(streakDays: Int) -> Bool {
        let milestones = [3, 7, 14, 30, 60, 100, 365]
        return milestones.contains(streakDays)
    }
    
    // Get streak milestone message
    static func getStreakMilestoneMessage(streakDays: Int) -> String {
        switch streakDays {
        case 3: return "3-day streak! Keep it up! 🔥"
        case 7: return "Week warrior! Amazing dedication! 🏆"
        case 14: return "Two-week streak! You're on fire! ⚡"
        case 30: return "Monthly master! Incredible consistency! 🌟"
        case 60: return "Two-month streak! Legendary dedication! 👑"
        case 100: return "Century streak! You're unstoppable! 🚀"
        case 365: return "One year! You're a learning legend! 🎉"
        default: return "Streak: \(streakDays) days! Keep going!"
        }
    }
    
    // Phase 1: Daily streak bonus multiplier
    static func getStreakBonusMultiplier(streakDays: Int) -> Double {
        // 1.5x XP on streak days, caps at 2.0x for long streaks
        let baseMultiplier = 1.5
        let bonus = min(0.5, Double(streakDays) * 0.01) // Max 0.5 additional
        return baseMultiplier + bonus
    }
    
    // Check if eligible for streak freeze award (weekly)
    static func shouldAwardStreakFreeze(lastAwardDate: Date?) -> Bool {
        guard let lastAward = lastAwardDate else { return true }
        let daysSinceAward = Calendar.current.dateComponents([.day], from: lastAward, to: Date()).day ?? 0
        return daysSinceAward >= 7
    }
}

// Phase 1: Streak celebration view
struct StreakCelebrationView: View {
    let streakDays: Int
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
                    Text("🔥")
                        .font(.system(size: 80))
                    
                    Text("Streak Milestone!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text(StreakManager.getStreakMilestoneMessage(streakDays: streakDays))
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("\(streakDays) days")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.orange)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Awesome!")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(32)
                .background(Color.orange.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            SoundEffectsManager.shared.playStreakSound()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}
