import SwiftUI
import Charts

struct ReportDetailView: View {
    let studentId: String
    let studentName: String

    @State private var paths: [LearningPath] = []
    @State private var progressMap: [String: StudentProgress] = [:]
    @State private var contentItems: [String: ContentItem] = [:]
    @State private var badges: [Badge] = []
    @State private var isLoading = true
    @State private var pdfURL: URL?

    // MARK: - Derived data

    private var allItems: [LearningPathItem] { paths.flatMap(\.items) }

    private var completedCount: Int {
        allItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }
    private var totalCount: Int { allItems.count }
    private var overallFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    private var weeklyData: [WeekData] {
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

    private var standardsCoverage: [(standard: Standard, covered: Bool)] {
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
        return codes.sorted()
            .compactMap { code -> (standard: Standard, covered: Bool)? in
                guard let std = TestDataProvider.standard(for: code) else { return nil }
                return (std, coveredCodes.contains(code))
            }
    }

    private var subjectStats: [SubjectStat] {
        var map: [String: (Int, Int)] = [:]
        for item in contentItems.values {
            let subject = item.subject.isEmpty ? "General" : item.subject
            let done    = progressMap[item.id]?.status == .completed ? 1 : 0
            let existing = map[subject] ?? (0, 0)
            map[subject] = (existing.0 + done, existing.1 + 1)
        }
        return map
            .map { SubjectStat(subject: $0.key, completed: $0.value.0, total: $0.value.1) }
            .sorted { $0.total > $1.total }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        overallCard
                        weeklyChart
                        if !subjectStats.isEmpty { subjectTable }
                        if !standardsCoverage.isEmpty { standardsTable }
                        if !badges.isEmpty { badgesSummary }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("\(studentName) — Report")
        .inlineNavigationTitle()
        .toolbar {
            #if os(iOS)
            if let url = pdfURL {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            #endif
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Overall Card

    private var overallCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                ProgressRing(fraction: overallFraction, size: 90)
                VStack(alignment: .leading, spacing: 10) {
                    StatRow(value: "\(completedCount)", label: "Lessons Completed", color: .green)
                    StatRow(value: "\(totalCount - completedCount)", label: "Remaining", color: .orange)
                    StatRow(value: "\(badges.count)", label: "Badges Earned", color: .purple)
                }
            }
        }
        .padding(20)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Weekly Activity Chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Activity")
                .font(.headline)
                .padding(.horizontal, 20)

            Chart(weeklyData) { week in
                BarMark(
                    x: .value("Week", week.label),
                    y: .value("Lessons", week.count)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4))
            }
            .frame(height: 160)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Subject Breakdown

    private var subjectTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Subject")
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(subjectStats) { stat in
                    SubjectRow(stat: stat)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Standards Coverage Table

    private var standardsTable: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standards Coverage")
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(standardsCoverage, id: \.standard.id) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.covered ? "checkmark.seal.fill" : "circle.dashed")
                            .foregroundStyle(entry.covered ? Color.green : Color.secondary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.standard.code)
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                            Text(entry.standard.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(entry.covered ? "Covered" : "Not yet")
                            .font(.caption2.bold())
                            .foregroundStyle(entry.covered ? Color.green : Color.secondary)
                    }
                    .padding(12)
                    .background(Color.appGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Badges Summary

    private var badgesSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges Earned")
                .font(.headline)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(badges) { badge in
                        VStack(spacing: 6) {
                            Image(systemName: badge.badgeType.icon)
                                .font(.system(size: 26))
                                .foregroundStyle(badge.badgeType.color)
                                .frame(width: 52, height: 52)
                                .background(badge.badgeType.color.opacity(0.12))
                                .clipShape(Circle())
                            Text(badge.badgeType.title)
                                .font(.caption.bold())
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 72)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Load

    private func load() async {
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

        // Build PDF in background
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

// MARK: - Supporting Types

struct WeekData: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

// MARK: - Subject Row

private struct SubjectRow: View {
    let stat: SubjectStat

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.subject)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(stat.completed)/\(stat.total)  (\(stat.percent)%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.12))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(stat.fraction == 1.0 ? Color.green : Color.blue)
                        .frame(width: geo.size.width * stat.fraction, height: 5)
                }
            }
            .frame(height: 5)
        }
        .padding(12)
        .background(Color.appGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
