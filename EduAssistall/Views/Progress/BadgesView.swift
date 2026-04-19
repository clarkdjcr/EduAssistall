import SwiftUI

struct BadgesView: View {
    let studentId: String

    @State private var badges: [Badge] = []
    @State private var isLoading = true

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
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

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.badgeType.color.opacity(0.15))
                    .frame(width: 58, height: 58)
                Image(systemName: badge.badgeType.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(badge.badgeType.color)
            }
            Text(badge.badgeType.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
