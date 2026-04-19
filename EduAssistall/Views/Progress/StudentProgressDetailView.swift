import SwiftUI

// Used by parents and teachers to view a specific student's progress
struct StudentProgressDetailView: View {
    let studentId: String
    let studentEmail: String

    @State private var paths: [LearningPath] = []
    @State private var progressMap: [String: StudentProgress] = [:]
    @State private var isLoading = true

    private var allItems: [LearningPathItem] { paths.flatMap(\.items) }
    private var completedCount: Int {
        allItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }
    private var totalCount: Int { allItems.count }
    private var overallFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Overall stats
                        VStack(spacing: 16) {
                            HStack(spacing: 24) {
                                ProgressRing(fraction: overallFraction, size: 90)
                                VStack(alignment: .leading, spacing: 10) {
                                    StatRow(value: "\(completedCount)", label: "Lessons Completed", color: .green)
                                    StatRow(value: "\(totalCount - completedCount)", label: "Remaining", color: .orange)
                                    StatRow(value: "\(paths.count)", label: "Learning Paths", color: .blue)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                        if paths.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.tertiary)
                                Text("No learning paths assigned yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 30)
                        } else {
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
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(studentEmail)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    ReportDetailView(studentId: studentId, studentName: studentEmail)
                } label: {
                    Image(systemName: "chart.bar.doc.horizontal")
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        async let fetchPaths = FirestoreService.shared.fetchAllLearningPaths(studentId: studentId)
        async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: studentId)

        let loadedPaths = (try? await fetchPaths) ?? []
        let progressList = (try? await fetchProgress) ?? []

        paths = loadedPaths.sorted { $0.createdAt > $1.createdAt }
        progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })
        isLoading = false
    }
}
