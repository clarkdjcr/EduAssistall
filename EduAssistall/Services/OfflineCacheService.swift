import Foundation

final class OfflineCacheService {
    static let shared = OfflineCacheService()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Learning Paths

    func cacheLearningPaths(_ paths: [LearningPath], for studentId: String) {
        guard let data = try? encoder.encode(paths) else { return }
        defaults.set(data, forKey: pathsKey(studentId))
    }

    func cachedLearningPaths(for studentId: String) -> [LearningPath] {
        guard let data = defaults.data(forKey: pathsKey(studentId)),
              let paths = try? decoder.decode([LearningPath].self, from: data) else { return [] }
        return paths
    }

    // MARK: - Progress

    func cacheProgress(_ progress: [StudentProgress], for studentId: String) {
        guard let data = try? encoder.encode(progress) else { return }
        defaults.set(data, forKey: progressKey(studentId))
    }

    func cachedProgress(for studentId: String) -> [StudentProgress] {
        guard let data = defaults.data(forKey: progressKey(studentId)),
              let progress = try? decoder.decode([StudentProgress].self, from: data) else { return [] }
        return progress
    }

    // MARK: - Content Items

    func cacheContentItems(_ items: [ContentItem]) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: contentItemsKey)
    }

    func cachedContentItems() -> [ContentItem] {
        guard let data = defaults.data(forKey: contentItemsKey),
              let items = try? decoder.decode([ContentItem].self, from: data) else { return [] }
        return items
    }

    // MARK: - Clear

    func clearAll(for studentId: String) {
        defaults.removeObject(forKey: pathsKey(studentId))
        defaults.removeObject(forKey: progressKey(studentId))
        defaults.removeObject(forKey: contentItemsKey)
    }

    // MARK: - Keys

    private func pathsKey(_ studentId: String) -> String { "offline_paths_\(studentId)" }
    private func progressKey(_ studentId: String) -> String { "offline_progress_\(studentId)" }
    private let contentItemsKey = "offline_content_items"
}
