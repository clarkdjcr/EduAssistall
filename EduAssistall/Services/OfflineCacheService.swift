import Foundation
import SwiftData

final class OfflineCacheService {
    static let shared = OfflineCacheService()

    private var container: ModelContainer?
    private let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d
    }()

    private init() {}

    /// Call once at app startup, before any cache reads or writes.
    func configure(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Learning Paths

    func cacheLearningPaths(_ paths: [LearningPath], for studentId: String) {
        guard let container else { return }
        let ctx = ModelContext(container)
        let old = fetch(CachedLearningPath.self, studentId: studentId, in: ctx)
        old.forEach { ctx.delete($0) }
        for path in paths {
            let itemsData = (try? encoder.encode(path.items)) ?? Data()
            ctx.insert(CachedLearningPath(
                id: path.id,
                studentId: path.studentId,
                title: path.title,
                pathDescription: path.description,
                isActive: path.isActive,
                answerModeEnabled: path.answerModeEnabled,
                createdAt: path.createdAt,
                itemsData: itemsData
            ))
        }
        try? ctx.save()
    }

    func cachedLearningPaths(for studentId: String) -> [LearningPath] {
        guard let container else { return [] }
        let ctx = ModelContext(container)
        return fetch(CachedLearningPath.self, studentId: studentId, in: ctx)
            .map { toLearningPath($0) }
    }

    // MARK: - Progress

    func cacheProgress(_ progress: [StudentProgress], for studentId: String) {
        guard let container else { return }
        let ctx = ModelContext(container)
        let old = fetch(CachedStudentProgress.self, studentId: studentId, in: ctx)
        old.forEach { ctx.delete($0) }
        for p in progress {
            ctx.insert(CachedStudentProgress(
                id: p.id,
                studentId: p.studentId,
                contentItemId: p.contentItemId,
                statusRaw: p.status.rawValue,
                completionPercent: p.completionPercent,
                timeSpentMinutes: p.timeSpentMinutes,
                completedAt: p.completedAt,
                updatedAt: p.updatedAt
            ))
        }
        try? ctx.save()
    }

    func cachedProgress(for studentId: String) -> [StudentProgress] {
        guard let container else { return [] }
        let ctx = ModelContext(container)
        return fetch(CachedStudentProgress.self, studentId: studentId, in: ctx)
            .map { toStudentProgress($0) }
    }

    // MARK: - Clear

    func clearAll(for studentId: String) {
        guard let container else { return }
        let ctx = ModelContext(container)
        fetch(CachedLearningPath.self, studentId: studentId, in: ctx).forEach { ctx.delete($0) }
        fetch(CachedStudentProgress.self, studentId: studentId, in: ctx).forEach { ctx.delete($0) }
        try? ctx.save()
    }

    // MARK: - Helpers

    private func fetch<T: PersistentModel & HasStudentId>(
        _ type: T.Type, studentId: String, in ctx: ModelContext
    ) -> [T] {
        (try? ctx.fetch(FetchDescriptor<T>(predicate: #Predicate { $0.studentId == studentId }))) ?? []
    }

    private func toLearningPath(_ c: CachedLearningPath) -> LearningPath {
        let items = (try? decoder.decode([LearningPathItem].self, from: c.itemsData)) ?? []
        var path = LearningPath(title: c.title, description: c.pathDescription,
                                studentId: c.studentId, createdBy: "")
        path.id = c.id
        path.isActive = c.isActive
        path.answerModeEnabled = c.answerModeEnabled
        path.createdAt = c.createdAt
        path.items = items
        return path
    }

    private func toStudentProgress(_ c: CachedStudentProgress) -> StudentProgress {
        var p = StudentProgress(studentId: c.studentId, contentItemId: c.contentItemId)
        p.id = c.id
        p.status = CompletionStatus(rawValue: c.statusRaw) ?? .notStarted
        p.completionPercent = c.completionPercent
        p.timeSpentMinutes = c.timeSpentMinutes
        p.completedAt = c.completedAt
        p.updatedAt = c.updatedAt
        return p
    }
}

// Protocol used to constrain the generic fetch helper to types with a studentId field.
protocol HasStudentId {
    var studentId: String { get }
}
extension CachedLearningPath: HasStudentId {}
extension CachedStudentProgress: HasStudentId {}
