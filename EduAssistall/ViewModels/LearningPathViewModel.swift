import Foundation

@Observable
final class LearningPathViewModel {
    var paths: [LearningPath] = []
    var progressMap: [String: StudentProgress] = [:]
    var isLoading = false

    func load(studentId: String) async {
        isLoading = true
        if ConnectivityService.shared.isOnline {
            async let fetchPaths = FirestoreService.shared.fetchLearningPaths(studentId: studentId)
            async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: studentId)

            let loadedPaths = (try? await fetchPaths) ?? []
            let progressList = (try? await fetchProgress) ?? []

            paths = loadedPaths.sorted { $0.createdAt > $1.createdAt }
            progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })

            OfflineCacheService.shared.cacheLearningPaths(paths, for: studentId)
            OfflineCacheService.shared.cacheProgress(progressList, for: studentId)
        } else {
            paths = OfflineCacheService.shared.cachedLearningPaths(for: studentId)
            let cached = OfflineCacheService.shared.cachedProgress(for: studentId)
            progressMap = Dictionary(uniqueKeysWithValues: cached.map { ($0.contentItemId, $0) })
        }
        isLoading = false
    }
}
