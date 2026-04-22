import SwiftUI

struct StudentProgressView: View {
    let profile: UserProfile

    @State private var paths: [LearningPath] = []
    @State private var progressMap: [String: StudentProgress] = [:]
    @State private var contentItems: [String: ContentItem] = [:]
    @State private var gradeBand: GradeBand = .sixToEight   // FR-303
    @State private var isLoading = true

    private var allItems: [LearningPathItem] { paths.flatMap(\.items) }

    private var coveredStandards: [Standard] {
        let completedIds = allItems
            .filter { progressMap[$0.contentItemId]?.status == .completed }
            .map(\.contentItemId)
        let codes = completedIds.compactMap { contentItems[$0] }.flatMap(\.alignedStandards)
        let unique = Array(Set(codes))
        return unique.compactMap { TestDataProvider.standard(for: $0) }.sorted { $0.code < $1.code }
    }
    private var completedCount: Int {
        allItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }
    private var totalCount: Int { allItems.count }
    private var overallFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            overallCard
                            if paths.isEmpty {
                                emptyState
                            } else {
                                pathsSection
                            }
                            if !coveredStandards.isEmpty { standardsSection }
                            badgesSection
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("My Progress")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    // MARK: - Overall Card (FR-303: switches on grade band)

    @ViewBuilder
    private var overallCard: some View {
        switch gradeBand {
        case .kTo2:
            EarlyProgressCard(completed: completedCount, total: totalCount)
                .padding(.horizontal, 20)
        case .threeToFive:
            ElementaryProgressCard(completed: completedCount, total: totalCount, fraction: overallFraction)
                .padding(.horizontal, 20)
        case .sixToEight, .nineTo12:
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    ProgressRing(fraction: overallFraction, size: 90)
                    VStack(alignment: .leading, spacing: 10) {
                        StatRow(value: "\(completedCount)", label: "Lessons Completed", color: .green)
                        StatRow(value: "\(totalCount - completedCount)", label: "Remaining", color: .orange)
                        StatRow(value: "\(paths.count)", label: "Learning Paths", color: .blue)
                        if gradeBand == .nineTo12, totalCount > 0 {
                            StatRow(
                                value: "\(Int(overallFraction * 100))%",
                                label: "Completion Rate",
                                color: overallFraction >= 0.75 ? .green : .blue
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Standards Readiness Section

    private var standardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standards Covered")
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(coveredStandards) { std in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(std.code)
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                            Text(std.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Badges Section

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.headline)
                .padding(.horizontal, 20)
            BadgesView(studentId: profile.id)
        }
    }

    // MARK: - Paths Section

    private var pathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Paths")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(paths) { path in
                PathProgressCard(path: path, progressMap: progressMap)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Progress Yet")
                .font(.title3.bold())
            Text("Your progress will appear here once your teacher assigns a learning path.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func load() async {
        isLoading = true
        async let fetchPaths = FirestoreService.shared.fetchAllLearningPaths(studentId: profile.id)
        async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: profile.id)
        async let fetchLearningProfile = FirestoreService.shared.fetchLearningProfile(studentId: profile.id)

        let loadedPaths = (try? await fetchPaths) ?? []
        let progressList = (try? await fetchProgress) ?? []
        if let lp = try? await fetchLearningProfile {
            gradeBand = GradeBand.from(grade: lp.grade)
        }

        paths = loadedPaths.sorted { $0.createdAt > $1.createdAt }
        progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })

        let allIds = loadedPaths.flatMap { $0.items.map(\.contentItemId) }
        let items = (try? await FirestoreService.shared.fetchContentItems(ids: allIds)) ?? []
        contentItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        isLoading = false
    }
}

// MARK: - Shared Progress Ring

struct ProgressRing: View {
    let fraction: Double
    let size: CGFloat

    private var percent: Int { Int(fraction * 100) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: fraction)
            VStack(spacing: 0) {
                Text("\(percent)%")
                    .font(.title3.bold())
                Text("done")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Shared Path Progress Card

struct PathProgressCard: View {
    let path: LearningPath
    let progressMap: [String: StudentProgress]

    private var completed: Int {
        path.items.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }
    private var total: Int { path.items.count }
    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(path.title)
                        .font(.subheadline.bold())
                    Text("\(completed) of \(total) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if completed == total && total > 0 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(fraction == 1.0 ? Color.green : Color.blue)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: fraction)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - FR-303: Early Learner Progress Card (K-2)
// Stars instead of percentages — concrete, visual, age-appropriate.

private struct EarlyProgressCard: View {
    let completed: Int
    let total: Int

    private var starCount: Int { min(total, 10) }
    private var filledStars: Int { total > 0 ? Int(Double(completed) / Double(total) * Double(starCount)) : 0 }
    private var label: String {
        switch completed {
        case 0:      return "Let's get started!"
        case 1:      return "Great start!"
        case total where total > 0: return "Amazing — all done!"
        default:     return "Keep going, you're doing great!"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(0..<starCount, id: \.self) { i in
                    Image(systemName: i < filledStars ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(i < filledStars ? Color.yellow : Color.secondary.opacity(0.3))
                        .animation(.spring(duration: 0.4).delay(Double(i) * 0.05), value: filledStars)
                }
            }
            Text(label)
                .font(.headline)
            if total > 10 {
                Text("\(completed) of \(total) lessons done")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.yellow.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - FR-303: Elementary Progress Card (3-5)
// Colorful bar with friendly labels.

private struct ElementaryProgressCard: View {
    let completed: Int
    let total: Int
    let fraction: Double

    private var encouragement: String {
        switch fraction {
        case 0:          return "Ready to start your adventure?"
        case ..<0.33:    return "You're off to a great start!"
        case ..<0.67:    return "Halfway there — keep it up!"
        case ..<1.0:     return "Almost there, finish strong!"
        default:         return "You did it! Path complete!"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("📚")
                    .font(.title)
                Spacer()
                Text(encouragement)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.trailing)
                Spacer()
                Text("🏆")
                    .font(.title)
                    .opacity(fraction >= 1.0 ? 1 : 0.25)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                        .frame(height: 14)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * fraction, height: 14)
                        .animation(.easeInOut(duration: 0.7), value: fraction)
                }
            }
            .frame(height: 14)

            HStack {
                Text("\(completed) lessons done")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                Spacer()
                Text("\(total - completed) to go")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color.green.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
                .frame(width: 36, alignment: .leading)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
