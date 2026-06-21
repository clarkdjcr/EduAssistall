import SwiftUI

struct BadgesView: View {
    let studentId: String

    @State private var badges: [Badge] = []
    @State private var isLoading = true

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    // Phase 1: Collection progress
    private var totalBadgeTypes: Int { BadgeType.allCases.count }
    private var earnedBadges: Int { badges.count }
    private var collectionProgress: Double {
        guard totalBadgeTypes > 0 else { return 0 }
        return Double(earnedBadges) / Double(totalBadgeTypes)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Phase 1: Collection progress
            if !badges.isEmpty {
                CollectionProgressCard(
                    earned: earnedBadges,
                    total: totalBadgeTypes,
                    progress: collectionProgress
                )
                .padding(.horizontal, 20)
            }
            
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if badges.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(badges) { badge in
                            BadgeCell(badge: badge)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .task { await load() }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "rosette")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No Badges Yet")
                .font(.subheadline.bold())
            Text("Complete lessons and quizzes to earn badges.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func load() async {
        isLoading = true
        badges = (try? await FirestoreService.shared.fetchBadges(studentId: studentId)) ?? []
        isLoading = false
    }
}

// MARK: - Badge Cell

struct BadgeCell: View {
    let badge: Badge
    
    // Phase 1: Rarity display
    private var rarity: BadgeRarity { badge.badgeType.rarity }
    private var rarityColor: Color { rarity.color }
    private var glowIntensity: Double { rarity.glowIntensity }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.badgeType.color.opacity(0.15))
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle()
                            .stroke(rarityColor.opacity(glowIntensity), lineWidth: glowIntensity > 0 ? 3 : 0)
                    )
                Image(systemName: badge.badgeType.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(badge.badgeType.color)
                    .shadow(color: rarityColor.opacity(glowIntensity), radius: glowIntensity > 0 ? 8 : 0)
            }
            Text(badge.badgeType.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
            // Phase 1: Rarity badge
            Text(rarity.displayName)
                .font(.caption2)
                .foregroundStyle(rarityColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Phase 1: Collection Progress Card

struct CollectionProgressCard: View {
    let earned: Int
    let total: Int
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Badge Collection")
                        .font(.headline)
                    Text("\(earned) of \(total) earned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(.blue)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
