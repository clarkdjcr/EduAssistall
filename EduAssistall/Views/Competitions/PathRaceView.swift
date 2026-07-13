import SwiftUI

// Phase 5A: Path race overview and progress
struct PathRaceView: View {
    let profile: UserProfile
    let race: PathRace
    let progress: PathRaceProgress?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "flag.fill")
                        .font(.title)
                        .foregroundStyle(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(race.title)
                        .font(.title2.bold())
                    Text(race.learningPathTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let progress = progress, progress.rewardsClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            
            Divider()
            
            // Description
            Text(race.description)
                .font(.body)
                .foregroundStyle(.secondary)
            
            // Progress card
            if let progress = progress {
                progressCard(progress: progress)
            }
            
            // Time remaining
            timeRemainingCard
            
            // Rewards
            rewardsCard
            
            Spacer()
            
            // Action button
            if let progress = progress {
                if progress.rewardsClaimed {
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
                } else if progress.pathCompletionPercent >= 100 {
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
                        // Continue path
                    } label: {
                        Text("Continue Race")
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
                    // Join race
                } label: {
                    Text("Join Race")
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
    
    private func progressCard(progress: PathRaceProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (Double(progress.pathCompletionPercent) / 100), height: 12)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("\(progress.pathCompletionPercent)% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(progress.itemsCompleted)/\(progress.totalItems) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                StatItem(label: "Rank", value: "#\(progress.currentRank)")
                StatItem(label: "Time", value: formatTime(progress.timeElapsed))
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    
    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards")
                .font(.headline)
            
            HStack(spacing: 16) {
                RewardItem(icon: "star.fill", label: "\(race.rewardStructure.xpReward) XP", color: .purple)
                
                if let badge = race.rewardStructure.badgeReward {
                    RewardItem(icon: badge.icon, label: badge.title, color: .yellow)
                }
                
                if let avatar = race.rewardStructure.avatarReward {
                    RewardItem(icon: avatar.icon, label: avatar.displayName, color: .blue)
                }
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func formatTimeRemaining() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: race.endDate)
        
        if let days = components.day, days > 0 {
            return "\(days)d \(components.hour ?? 0)h"
        } else {
            return "\(components.hour ?? 0)h"
        }
    }
    
    private func claimRewards() {
        guard let progress = progress else { return }
        
        Task {
            do {
                try await PathRaceService.shared.awardRaceRewards(progress: progress, race: race)
            } catch {
                // Handle error
            }
        }
    }
}

// Phase 5A: Real-time race standings
struct RaceLeaderboardView: View {
    let race: PathRace
    let progressEntries: [PathRaceProgress]
    
    var body: some View {
        List {
            ForEach(progressEntries) { progress in
                HStack(spacing: 12) {
                    Text("#\(progress.currentRank)")
                        .font(.headline.bold())
                        .foregroundStyle(progress.currentRank <= 3 ? .yellow : .green)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Student \(progress.studentId.prefix(4))")
                            .font(.subheadline.bold())
                        Text("\(progress.pathCompletionPercent)% complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(progress.itemsCompleted)/\(progress.totalItems)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatTime(progress.timeElapsed))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Race Standings")
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// Phase 5A: Individual progress display
struct RaceProgressCard: View {
    let progress: PathRaceProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Race Progress")
                    .font(.headline)
                Spacer()
                Text("#\(progress.currentRank)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.green, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (Double(progress.pathCompletionPercent) / 100), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(progress.pathCompletionPercent)%")
                    .font(.caption)
                Spacer()
                Text("\(progress.itemsCompleted)/\(progress.totalItems)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
