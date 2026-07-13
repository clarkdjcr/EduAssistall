import SwiftUI

// Phase 5A: Main leaderboard interface
struct LeaderboardView: View {
    let profile: UserProfile
    let classId: String?
    
    @State private var config = LeaderboardConfig()
    @State private var entries: [LeaderboardEntry] = []
    @State private var userRank: Int?
    @State private var isLoading = true
    @State private var showFilterSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading leaderboard...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // User's rank card
                        if let rank = userRank {
                            userRankCard(rank: rank)
                                .padding()
                        }
                        
                        // Leaderboard list
                        List {
                            ForEach(entries) { entry in
                                LeaderboardRow(entry: entry, isCurrentUser: entry.studentId == profile.id)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                LeaderboardFilterView(config: $config) { newConfig in
                    config = newConfig
                    Task { await loadLeaderboard() }
                }
            }
            .task {
                await loadLeaderboard()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Leaderboard Data")
                .font(.headline)
            Text("Leaderboard will populate as students earn XP")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func userRankCard(rank: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(rank <= 3 ? Color.yellow.opacity(0.2) : Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                Text("#\(rank)")
                    .font(.title2.bold())
                    .foregroundStyle(rank <= 3 ? .yellow : .blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rank")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Level \(profile.level)")
                    .font(.headline)
                Text("\(profile.xp) XP")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Category icon
            Image(systemName: config.category.icon)
                .font(.title2)
                .foregroundStyle(.blue)
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func loadLeaderboard() async {
        isLoading = true
        do {
            entries = try await FirestoreService.shared.fetchLeaderboardEntries(config: config, classId: classId)
            entries = LeaderboardService.shared.calculateRanks(entries: entries, category: config.category)
            userRank = LeaderboardService.shared.getUserRank(entries: entries, userId: profile.id)
        } catch {
            entries = []
        }
        isLoading = false
    }
}

// Phase 5A: Individual leaderboard entry display
struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text("#\(entry.rank)")
                    .font(.headline.bold())
                    .foregroundStyle(rankColor)
            }
            
            // Avatar or initials
            if let avatarConfig = entry.avatarConfig {
                AvatarPreviewView(config: avatarConfig)
                    .frame(width: 44, height: 44)
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(entry.studentName.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundStyle(.blue)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.studentName)
                    .font(.subheadline.bold())
                HStack(spacing: 12) {
                    Label("\(entry.xp) XP", systemImage: "star.fill")
                        .font(.caption2)
                    Label("Lvl \(entry.level)", systemImage: "arrow.up")
                        .font(.caption2)
                    Label("\(entry.badgeCount)", systemImage: "rosette")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Rank change indicator
            rankChangeIndicator
        }
        .padding(.vertical, 8)
        .background(isCurrentUser ? Color.blue.opacity(0.05) : Color.clear)
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    @ViewBuilder
    private var rankChangeIndicator: some View {
        switch entry.rankChange {
        case .up:
            Image(systemName: "arrow.up")
                .foregroundStyle(.green)
        case .down:
            Image(systemName: "arrow.down")
                .foregroundStyle(.red)
        case .same:
            Image(systemName: "minus")
                .foregroundStyle(.gray)
        case .new:
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
        }
    }
}

// Phase 5A: Filter selection interface
struct LeaderboardFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var config: LeaderboardConfig
    let onApply: (LeaderboardConfig) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Time Period") {
                    ForEach(LeaderboardConfig.TimePeriod.allCases, id: \.self) { period in
                        Button {
                            config.timePeriod = period
                        } label: {
                            HStack {
                                Text(period.displayName)
                                Spacer()
                                if config.timePeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Category") {
                    ForEach(LeaderboardConfig.Category.allCases, id: \.self) { category in
                        Button {
                            config.category = category
                        } label: {
                            HStack {
                                Label(category.displayName, systemImage: category.icon)
                                Spacer()
                                if config.category == category {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Scope") {
                    ForEach(LeaderboardConfig.Scope.allCases, id: \.self) { scope in
                        Button {
                            config.scope = scope
                        } label: {
                            HStack {
                                Text(scope.displayName)
                                Spacer()
                                if config.scope == scope {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(config)
                        dismiss()
                    }
                }
            }
        }
    }
}
