import SwiftUI

// Phase 5A: Streak competition overview
struct StreakCompetitionView: View {
    let profile: UserProfile
    let competition: StreakCompetition
    let entry: StreakCompetitionEntry?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(competition.title)
                        .font(.title2.bold())
                    Text("\(competition.streakTarget)-day streak challenge")
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
            Text(competition.description)
                .font(.body)
                .foregroundStyle(.secondary)
            
            // Progress card
            if let entry = entry {
                progressCard(entry: entry)
            }
            
            // Bonus multiplier
            bonusMultiplierCard
            
            // Time remaining
            timeRemainingCard
            
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
                } else if entry.targetReached {
                    Button {
                        claimRewards()
                    } label: {
                        Text("Claim Rewards")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Button {
                        // Continue learning
                    } label: {
                        Text("Keep Learning")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                Button {
                    // Join competition
                } label: {
                    Text("Join Competition")
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
    }
    
    private func progressCard(entry: StreakCompetitionEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            // Streak progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Streak")
                        .font(.subheadline)
                    Spacer()
                    Text("\(entry.currentStreak) days")
                        .font(.headline.bold())
                        .foregroundStyle(.orange)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(1.0, Double(entry.currentStreak) / Double(competition.streakTarget)), height: 12)
                    }
                }
                .frame(height: 12)
                
                Text("\(competition.streakTarget) day target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 20) {
                StatItem(label: "Best Streak", value: "\(entry.bestStreak)")
                StatItem(label: "Rank", value: "#\(entry.currentRank)")
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var bonusMultiplierCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "multiply.circle.fill")
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text("XP Bonus Active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(competition.bonusMultiplier)x XP multiplier")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
            }
            Spacer()
        }
        .padding()
        .background(Color.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var timeRemainingCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Days Remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(entry?.daysRemaining ?? competition.durationDays) days")
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards")
                .font(.headline)
            
            HStack(spacing: 16) {
                RewardItem(icon: "star.fill", label: "\(competition.rewardStructure.xpReward) XP", color: .purple)
                
                if let badge = competition.rewardStructure.badgeReward {
                    RewardItem(icon: badge.icon, label: badge.title, color: .yellow)
                }
                
                if competition.rewardStructure.streakFreezeReward > 0 {
                    RewardItem(icon: "snowflake", label: "\(competition.rewardStructure.streakFreezeReward) Freeze", color: .cyan)
                }
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func claimRewards() {
        guard let entry = entry else { return }
        
        Task {
            do {
                try await StreakCompetitionService.shared.awardCompetitionRewards(entry: entry, competition: competition)
            } catch {
                // Handle error
            }
        }
    }
}

// Phase 5A: Streak rankings
struct StreakLeaderboardView: View {
    let competition: StreakCompetition
    let entries: [StreakCompetitionEntry]
    
    var body: some View {
        List {
            ForEach(entries) { entry in
                HStack(spacing: 12) {
                    Text("#\(entry.currentRank)")
                        .font(.headline.bold())
                        .foregroundStyle(entry.currentRank <= 3 ? .yellow : .orange)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Student \(entry.studentId.prefix(4))")
                            .font(.subheadline.bold())
                        HStack(spacing: 8) {
                            Text("\(entry.currentStreak) day streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if entry.targetReached {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Best: \(entry.bestStreak)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(entry.daysRemaining)d left")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Streak Rankings")
    }
}

// Phase 5A: Display active bonuses
struct StreakBonusCard: View {
    let competition: StreakCompetition
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "multiply.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(competition.title)
                    .font(.subheadline.bold())
                Text("\(competition.bonusMultiplier)x XP active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(competition.streakTarget) day target")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
