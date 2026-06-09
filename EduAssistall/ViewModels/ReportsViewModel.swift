import Foundation

struct WeekData: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

@Observable
final class ReportsViewModel {
    var paths: [LearningPath] = []
    var progressMap: [String: StudentProgress] = [:]
    var contentItems: [String: ContentItem] = [:]
    var badges: [Badge] = []
    var isLoading = false
    var pdfURL: URL?

    var allItems: [LearningPathItem] { paths.flatMap(\.items) }

    var completedCount: Int {
        allItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }

    var totalCount: Int { allItems.count }

    var overallFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var weeklyData: [WeekData] {
        let cal = Calendar.current
        let now = Date()
        return (0..<6).reversed().map { weeksAgo in
            let anchor = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: now)!
            let start  = cal.startOfDay(for: cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor))!)
            let end    = cal.date(byAdding: .weekOfYear, value: 1, to: start)!
            let count  = progressMap.values.filter { p in
                p.status == .completed && (p.completedAt.map { $0 >= start && $0 < end } ?? false)
            }.count
            let label  = start.formatted(.dateTime.month(.abbreviated).day())
            return WeekData(label: label, count: count)
        }
    }

    var standardsCoverage: [(standard: Standard, covered: Bool)] {
        var codes: Set<String> = []
        var coveredCodes: Set<String> = []
        for item in contentItems.values {
            for code in item.alignedStandards {
                codes.insert(code)
                if progressMap[item.id]?.status == .completed {
                    coveredCodes.insert(code)
                }
            }
        }
        return codes.sorted().compactMap { code -> (standard: Standard, covered: Bool)? in
            guard let std = TestDataProvider.standard(for: code) else { return nil }
            return (std, coveredCodes.contains(code))
        }
    }

    var subjectStats: [SubjectStat] {
        var map: [String: (Int, Int)] = [:]
        for item in contentItems.values {
            let subject  = item.subject.isEmpty ? "General" : item.subject
            let done     = progressMap[item.id]?.status == .completed ? 1 : 0
            let existing = map[subject] ?? (0, 0)
            map[subject] = (existing.0 + done, existing.1 + 1)
        }
        return map
            .map { SubjectStat(subject: $0.key, completed: $0.value.0, total: $0.value.1) }
            .sorted { $0.total > $1.total }
    }

    func load(studentId: String, studentName: String) async {
        isLoading = true
        async let fetchPaths    = FirestoreService.shared.fetchAllLearningPaths(studentId: studentId)
        async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: studentId)
        async let fetchBadges   = FirestoreService.shared.fetchBadges(studentId: studentId)

        let loadedPaths  = (try? await fetchPaths)    ?? []
        let progressList = (try? await fetchProgress) ?? []
        badges           = (try? await fetchBadges)   ?? []

        paths       = loadedPaths
        progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })

        let allIds = loadedPaths.flatMap { $0.items.map(\.contentItemId) }
        let items  = (try? await FirestoreService.shared.fetchContentItems(ids: allIds)) ?? []
        contentItems = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        let snapshot = ReportSnapshot(
            studentName:    studentName,
            completedCount: completedCount,
            totalCount:     totalCount,
            badgeCount:     badges.count,
            subjectStats:   subjectStats,
            generatedAt:    Date()
        )
        pdfURL = PDFExportService.generateReport(snapshot)
        isLoading = false
    }
}
