import SwiftUI
import Charts

struct ReportDetailView: View {
    let studentId: String
    let studentName: String

    @State private var vm = ReportsViewModel()

    // MARK: - Body

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        overallCard
                        weeklyChart
                        if !vm.subjectStats.isEmpty { subjectTable }
                        if !vm.standardsCoverage.isEmpty { standardsTable }
                        if !vm.badges.isEmpty { badgesSummary }
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
            if let url = vm.pdfURL {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            #endif
        }
        .task { await vm.load(studentId: studentId, studentName: studentName) }
        .refreshable { await vm.load(studentId: studentId, studentName: studentName) }
    }

    // MARK: - Overall Card

    private var overallCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                ProgressRing(fraction: vm.overallFraction, size: 90)
                VStack(alignment: .leading, spacing: 10) {
                    StatRow(value: "\(vm.completedCount)", label: "Lessons Completed", color: .green)
                    StatRow(value: "\(vm.totalCount - vm.completedCount)", label: "Remaining", color: .orange)
                    StatRow(value: "\(vm.badges.count)", label: "Badges Earned", color: .purple)
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

            Chart(vm.weeklyData) { week in
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
                ForEach(vm.subjectStats) { stat in
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
                ForEach(vm.standardsCoverage, id: \.standard.id) { entry in
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
                    ForEach(vm.badges) { badge in
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
