import SwiftUI

struct LearningPathDetailView: View {
    let path: LearningPath
    let studentId: String

    @State private var contentItems: [String: ContentItem] = [:]
    @State private var progressMap: [String: StudentProgress] = [:]
    @State private var isLoading = true

    private var sortedItems: [LearningPathItem] { path.sortedItems }

    private var completedCount: Int {
        sortedItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }

    private var progressFraction: Double {
        guard !sortedItems.isEmpty else { return 0 }
        return Double(completedCount) / Double(sortedItems.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(path.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: geo.size.width * progressFraction, height: 8)
                            }
                        }
                        .frame(height: 8)

                        Text("\(completedCount) of \(sortedItems.count) items completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)

                // Content items list
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                            if let content = contentItems[item.contentItemId] {
                                NavigationLink {
                                    ContentItemView(
                                        item: content,
                                        studentId: studentId,
                                        existingProgress: progressMap[content.id]
                                    ) { updated in
                                        progressMap[updated.contentItemId] = updated
                                    }
                                } label: {
                                    ContentItemRow(
                                        item: content,
                                        stepNumber: index + 1,
                                        progress: progressMap[content.id]
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(path.title)
        .inlineNavigationTitle()
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        let ids = sortedItems.map(\.contentItemId)

        async let fetchItems = FirestoreService.shared.fetchContentItems(ids: ids)
        async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: studentId)

        let items = (try? await fetchItems) ?? []
        let progressList = (try? await fetchProgress) ?? []

        contentItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })
        isLoading = false
    }
}

// MARK: - Content Item Row

struct ContentItemRow: View {
    let item: ContentItem
    let stepNumber: Int
    let progress: StudentProgress?

    private var isComplete: Bool { progress?.status == .completed }

    var body: some View {
        HStack(spacing: 14) {
            // Step / completion indicator
            ZStack {
                Circle()
                    .fill(isComplete ? Color.green : Color.blue.opacity(0.12))
                    .frame(width: 36, height: 36)
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color.white)
                } else {
                    Text("\(stepNumber)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
            }

            // Content info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Image(systemName: item.contentType.icon)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(item.contentType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text("\(item.estimatedMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isComplete ? 0.75 : 1.0)
    }
}
