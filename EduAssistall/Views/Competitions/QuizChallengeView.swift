import SwiftUI

// Phase 5A: Quiz challenge overview and participation
struct QuizChallengeView: View {
    let profile: UserProfile
    let challenge: QuizChallenge
    let entry: QuizChallengeEntry?
    
    @State private var showRewardSheet = false
    @State private var isClaiming = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "checkmark.square.fill")
                        .font(.title)
                        .foregroundStyle(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.title2.bold())
                    Text(challenge.theme)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let entry = entry, entry.rewardsClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            
            Divider()
            
            // Description
            Text(challenge.description)
                .font(.body)
                .foregroundStyle(.secondary)
            
            // Time remaining
            timeRemainingCard
            
            // Participation stats
            if let entry = entry {
                participationStatsCard(entry: entry)
            }
            
            // Rewards
            rewardsCard
            
            Spacer()
            
            // Action button
            if let entry = entry {
                if entry.rewardsClaimed {
                    Button {
                        // Already claimed
                    } label: {
                        Text("Rewards Claimed")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(true)
                } else {
                    Button {
                        claimRewards()
                    } label: {
                        HStack {
                            if isClaiming {
                                ProgressView().tint(.white)
                            } else {
                                Text("Claim Rewards")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isClaiming)
                }
            } else {
                Button {
                    // Join challenge
                } label: {
                    Text("Join Challenge")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .sheet(isPresented: $showRewardSheet) {
            ChallengeRewardView(challenge: challenge)
        }
    }
    
    private var timeRemainingCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Time Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatTimeRemaining())
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func participationStatsCard(entry: QuizChallengeEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(label: "Attempts", value: "\(entry.quizAttempts.count)")
                StatItem(label: "Best Score", value: "\(entry.bestScore)")
                StatItem(label: "Rank", value: "#\(entry.rank)")
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards")
                .font(.headline)
            
            HStack(spacing: 16) {
                RewardItem(icon: "star.fill", label: "\(challenge.rewardStructure.xpReward) XP", color: .purple)
                
                if let badge = challenge.rewardStructure.badgeReward {
                    RewardItem(icon: badge.icon, label: badge.title, color: .yellow)
                }
                
                if challenge.rewardStructure.streakFreezeReward > 0 {
                    RewardItem(icon: "snowflake", label: "\(challenge.rewardStructure.streakFreezeReward) Freeze", color: .cyan)
                }
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatTimeRemaining() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: challenge.endDate)
        
        if let days = components.day, days > 0 {
            return "\(days)d \(components.hour ?? 0)h"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h \(components.minute ?? 0)m"
        } else {
            return "\(components.minute ?? 0)m"
        }
    }
    
    private func claimRewards() {
        guard let entry = entry else { return }
        
        Task {
            isClaiming = true
            do {
                try await QuizChallengeService.shared.awardChallengeRewards(entry: entry, challenge: challenge)
                showRewardSheet = true
            } catch {
                // Handle error
            }
            isClaiming = false
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct RewardItem: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Phase 5A: Challenge-specific rankings
struct ChallengeLeaderboardView: View {
    let challenge: QuizChallenge
    let entries: [QuizChallengeEntry]
    
    var body: some View {
        List {
            ForEach(entries) { entry in
                HStack(spacing: 12) {
                    Text("#\(entry.rank)")
                        .font(.headline.bold())
                        .foregroundStyle(entry.rank <= 3 ? .yellow : .blue)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Student \(entry.studentId.prefix(4))")
                            .font(.subheadline.bold())
                        Text("\(entry.bestScore) points")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(entry.quizAttempts.count) attempts")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Challenge Rankings")
    }
}

// Phase 5A: Display earned rewards
struct ChallengeRewardView: View {
    let challenge: QuizChallenge
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                ConfettiView()
                    .allowsHitTesting(false)
                
                VStack(spacing: 20) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.yellow)
                    
                    Text("Challenge Complete!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("You earned:")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    VStack(spacing: 12) {
                        RewardDisplay(icon: "star.fill", label: "\(challenge.rewardStructure.xpReward) XP", color: .purple)
                        
                        if let badge = challenge.rewardStructure.badgeReward {
                            RewardDisplay(icon: badge.icon, label: badge.title, color: .yellow)
                        }
                        
                        if challenge.rewardStructure.streakFreezeReward > 0 {
                            RewardDisplay(icon: "snowflake", label: "\(challenge.rewardStructure.streakFreezeReward) Streak Freeze", color: .cyan)
                        }
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Awesome!")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(Color.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(32)
                .background(Color.yellow.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            SoundEffectsManager.shared.playAchievementSound()
        }
    }
}

private struct RewardDisplay: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
