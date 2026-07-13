import SwiftUI

// Phase 5A: Tournament overview and events
struct TournamentView: View {
    let profile: UserProfile
    let tournament: Tournament
    let participation: TournamentParticipation?
    
    @State private var selectedEvent: Tournament.TournamentEvent?
    @State private var showRewardSheet = false
    @State private var isClaiming = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                Divider()
                
                // Description
                Text(tournament.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                // Tournament type badge
                tournamentTypeBadge
                
                // Participation requirements
                requirementsCard
                
                // Events
                if !tournament.events.isEmpty {
                    eventsSection
                }
                
                // Progress
                if let participation = participation {
                    progressCard(participation: participation)
                }
                
                // Time remaining
                timeRemainingCard
                
                // Rewards
                rewardsCard
                
                // Action button
                actionButton
            }
            .padding()
        }
        .sheet(item: $selectedEvent) { event in
            TournamentEventDetailView(event: event, participation: participation)
        }
        .sheet(isPresented: $showRewardSheet) {
            TournamentRewardView(tournament: tournament)
        }
    }
    
    private var headerSection: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: tournament.tournamentType.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.title)
                    .font(.title2.bold())
                Text(tournament.theme)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let participation = participation, participation.rewardsClaimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }
        }
    }
    
    private var tournamentTypeBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: tournament.tournamentType.icon)
            Text(tournament.tournamentType.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.1))
        .foregroundStyle(.purple)
        .clipShape(Capsule())
    }
    
    private var requirementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requirements")
                .font(.headline)
            
            HStack(spacing: 16) {
                RequirementItem(icon: "arrow.up", label: "Level \(tournament.participationRequirements.minimumLevel)+")
                if !tournament.participationRequirements.requiredBadges.isEmpty {
                    RequirementItem(icon: "rosette", label: "\(tournament.participationRequirements.requiredBadges.count) badges")
                }
                if tournament.participationRequirements.minimumStreak > 0 {
                    RequirementItem(icon: "flame.fill", label: "\(tournament.participationRequirements.minimumStreak)+ streak")
                }
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tournament Events")
                .font(.headline)
            
            ForEach(tournament.events) { event in
                EventCard(event: event, participation: participation) {
                    selectedEvent = event
                }
            }
        }
    }
    
    private func progressCard(participation: TournamentParticipation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(label: "Points", value: "\(participation.totalPoints)")
                StatItem(label: "Rank", value: "#\(participation.currentRank)")
                StatItem(label: "Events", value: "\(participation.eventCompletions.count)/\(tournament.events.count)")
            }
            
            // Overall progress bar
            let completedCount = participation.eventCompletions.values.filter { $0.completed }.count
            let totalCount = tournament.events.count
            
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (Double(completedCount) / Double(totalCount)), height: 12)
                    }
                }
                .frame(height: 12)
                
                Text("\(completedCount)/\(totalCount) events completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                RewardItem(icon: "star.fill", label: "\(tournament.rewardStructure.xpReward) XP", color: .purple)
                
                if tournament.rewardStructure.xpMultiplier > 1.0 {
                    RewardItem(icon: "multiply.circle.fill", label: "\(tournament.rewardStructure.xpMultiplier)x multiplier", color: .pink)
                }
                
                if let badge = tournament.rewardStructure.badgeReward {
                    RewardItem(icon: badge.icon, label: badge.title, color: .yellow)
                }
                
                if let avatar = tournament.rewardStructure.avatarReward {
                    RewardItem(icon: avatar.icon, label: avatar.displayName, color: .blue)
                }
                
                if let title = tournament.rewardStructure.titleReward {
                    RewardItem(icon: "crown.fill", label: title, color: .orange)
                }
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if let participation = participation {
            if participation.rewardsClaimed {
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
            } else if participation.eventCompletions.count == tournament.events.count {
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
            } else {
                Button {
                    // Continue tournament
                } label: {
                    Text("Continue Tournament")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        } else {
            if TournamentService.shared.meetsRequirements(studentId: profile.id, tournament: tournament) {
                Button {
                    // Join tournament
                } label: {
                    Text("Join Tournament")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button {
                    // Requirements not met
                } label: {
                    Text("Requirements Not Met")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(true)
            }
        }
    }
    
    private func formatTimeRemaining() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: tournament.endDate)
        
        if let days = components.day, days > 0 {
            return "\(days)d \(components.hour ?? 0)h"
        } else {
            return "\(components.hour ?? 0)h"
        }
    }
    
    private func claimRewards() {
        guard let participation = participation else { return }
        
        Task {
            isClaiming = true
            do {
                try await TournamentService.shared.awardTournamentRewards(participation: participation, tournament: tournament)
                showRewardSheet = true
            } catch {
                // Handle error
            }
            isClaiming = false
        }
    }
}

private struct RequirementItem: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}

private struct EventCard: View {
    let event: Tournament.TournamentEvent
    let participation: TournamentParticipation?
    let onTap: () -> Void
    
    private var isCompleted: Bool {
        participation?.eventCompletions[event.id]?.completed ?? false
    }
    
    private var score: Int {
        participation?.eventCompletions[event.id]?.score ?? 0
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isCompleted ? .green : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.subheadline.bold())
                    Text(event.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(event.points) pts")
                        .font(.subheadline.bold())
                        .foregroundStyle(.purple)
                    if isCompleted {
                        Text("\(score) earned")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding()
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// Phase 5A: Tournament event detail
struct TournamentEventDetailView: View {
    let event: Tournament.TournamentEvent
    let participation: TournamentParticipation?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(event.title)
                    .font(.title2.bold())
                
                Text(event.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Event Details")
                        .font(.headline)
                    
                    HStack {
                        Label("Points", systemImage: "star.fill")
                        Spacer()
                        Text("\(event.points)")
                            .font(.headline)
                            .foregroundStyle(.purple)
                    }
                    
                    HStack {
                        Label("Starts", systemImage: "calendar")
                        Spacer()
                        Text(formatDate(event.startDate))
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Label("Ends", systemImage: "calendar")
                        Spacer()
                        Text(formatDate(event.endDate))
                            .font(.subheadline)
                    }
                }
                
                if let completion = participation?.eventCompletions[event.id] {
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Progress")
                            .font(.headline)
                        
                        if completion.completed {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Completed")
                                    .font(.headline)
                                Spacer()
                                Text("\(completion.score) points earned")
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Text("Not completed")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Phase 5A: Tournament rankings
struct TournamentLeaderboardView: View {
    let tournament: Tournament
    let participations: [TournamentParticipation]
    
    var body: some View {
        List {
            ForEach(participations) { participation in
                HStack(spacing: 12) {
                    Text("#\(participation.currentRank)")
                        .font(.headline.bold())
                        .foregroundStyle(participation.currentRank <= 3 ? .yellow : .purple)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Student \(participation.studentId.prefix(4))")
                            .font(.subheadline.bold())
                        let completedCount = participation.eventCompletions.values.filter { $0.completed }.count
                        Text("\(completedCount)/\(tournament.events.count) events")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(participation.totalPoints) pts")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        if participation.rewardsClaimed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Tournament Rankings")
    }
}

// Phase 5A: Special reward display
struct TournamentRewardView: View {
    let tournament: Tournament
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
                    Image(systemName: "crown.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.yellow)
                    
                    Text("Tournament Complete!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("You earned:")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    VStack(spacing: 12) {
                        let baseXP = tournament.rewardStructure.xpReward
                        let xpReward = Int(Double(baseXP) * tournament.rewardStructure.xpMultiplier)
                        RewardDisplay(icon: "star.fill", label: "\(xpReward) XP", color: .purple)
                        
                        if tournament.rewardStructure.xpMultiplier > 1.0 {
                            RewardDisplay(icon: "multiply.circle.fill", label: "\(tournament.rewardStructure.xpMultiplier)x multiplier", color: .pink)
                        }
                        
                        if let badge = tournament.rewardStructure.badgeReward {
                            RewardDisplay(icon: badge.icon, label: badge.title, color: .yellow)
                        }
                        
                        if let avatar = tournament.rewardStructure.avatarReward {
                            RewardDisplay(icon: avatar.icon, label: avatar.displayName, color: .blue)
                        }
                        
                        if let title = tournament.rewardStructure.titleReward {
                            RewardDisplay(icon: "crown.fill", label: title, color: .orange)
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

// Phase 5A: Upcoming tournaments calendar
struct TournamentCalendarView: View {
    let tournaments: [Tournament]
    
    var body: some View {
        List {
            ForEach(tournaments) { tournament in
                TournamentCalendarCard(tournament: tournament)
            }
        }
        .navigationTitle("Tournament Calendar")
    }
}

private struct TournamentCalendarCard: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: tournament.tournamentType.icon)
                        .font(.title2)
                        .foregroundStyle(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.title)
                        .font(.headline)
                    Text(tournament.theme)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDate(tournament.startDate))
                        .font(.subheadline.bold())
                    Text("\(tournament.events.count) events")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                Label("\(tournament.rewardStructure.xpReward) XP", systemImage: "star.fill")
                    .font(.caption)
                if let badge = tournament.rewardStructure.badgeReward {
                    Label(badge.title, systemImage: badge.icon)
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
