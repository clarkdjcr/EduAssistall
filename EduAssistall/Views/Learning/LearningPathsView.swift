import SwiftUI

struct LearningPathsView: View {
    let profile: UserProfile

    @State private var paths: [LearningPath] = []
    @State private var progressMap: [String: StudentProgress] = [:]
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if paths.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(paths) { path in
                                NavigationLink {
                                    LearningPathDetailView(
                                        path: path,
                                        studentId: profile.id
                                    )
                                } label: {
                                    LearningPathCard(path: path, progressMap: progressMap)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Learning")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No Learning Paths Yet")
                .font(.title3.bold())
            Text("Your teacher will assign a learning path soon. Check back later!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        if ConnectivityService.shared.isOnline {
            async let fetchPaths = FirestoreService.shared.fetchLearningPaths(studentId: profile.id)
            async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: profile.id)

            let loadedPaths = (try? await fetchPaths) ?? []
            let progressList = (try? await fetchProgress) ?? []

            paths = loadedPaths.sorted { $0.createdAt > $1.createdAt }
            progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })

            OfflineCacheService.shared.cacheLearningPaths(paths, for: profile.id)
            OfflineCacheService.shared.cacheProgress(progressList, for: profile.id)
        } else {
            paths = OfflineCacheService.shared.cachedLearningPaths(for: profile.id)
            let cached = OfflineCacheService.shared.cachedProgress(for: profile.id)
            progressMap = Dictionary(uniqueKeysWithValues: cached.map { ($0.contentItemId, $0) })
        }
        isLoading = false
    }
}

// MARK: - Path Card

struct LearningPathCard: View {
    let path: LearningPath
    let progressMap: [String: StudentProgress]

    private var completedCount: Int {
        path.items.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }

    private var totalCount: Int { path.items.count }

    private var progressFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(path.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: geo.size.width * progressFraction, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(completedCount) of \(totalCount) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if completedCount == totalCount && totalCount > 0 {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
