import SwiftUI

// Phase 3: Parent achievements feed view
struct ParentAchievementsView: View {
    let parentId: String
    
    @State private var achievements: [ParentAchievement] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading achievements...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if achievements.isEmpty {
                emptyState
            } else {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                        .onTapGesture {
                            Task {
                                try? await FirestoreService.shared.markAchievementViewed(
                                    achievementId: achievement.id,
                                    parentId: parentId
                                )
                            }
                        }
                }
            }
        }
        .navigationTitle("Child's Achievements")
        .task {
            await loadAchievements()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Achievements Yet")
                .font(.headline)
            Text("Your child's achievements will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadAchievements() async {
        isLoading = true
        achievements = (try? await FirestoreService.shared.fetchParentAchievements(parentId: parentId)) ?? []
        isLoading = false
    }
}

private struct AchievementCard: View {
    let achievement: ParentAchievement
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(formatDate(achievement.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if !achievement.viewed {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var iconName: String {
        switch achievement.achievementType {
        case .badge: return "rosette"
        case .levelUp: return "star.fill"
        case .streak: return "flame.fill"
        case .pathComplete: return "flag.checkered"
        }
    }
    
    private var iconColor: Color {
        switch achievement.achievementType {
        case .badge: return .purple
        case .levelUp: return .yellow
        case .streak: return .orange
        case .pathComplete: return .green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
