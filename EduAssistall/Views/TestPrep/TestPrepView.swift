import SwiftUI

struct TestPrepView: View {
    let profile: UserProfile

    @State private var attempts: [TestAttempt] = []
    @State private var isLoading = true
    @State private var selectedTest: PracticeTest?
    @State private var filterType: TestType? = nil

    private let tests = TestDataProvider.tests

    private var filtered: [PracticeTest] {
        guard let t = filterType else { return tests }
        return tests.filter { $0.type == t }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    typeFilter
                    testGrid
                    if !attempts.isEmpty { historySection }
                    Spacer(minLength: 32)
                }
                .padding(.vertical, 16)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Test Prep")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
            .sheet(item: $selectedTest) { test in
                PracticeTestView(test: test, studentId: profile.id) {
                    Task { await load() }
                }
            }
        }
    }

    // MARK: - Type Filter

    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", type: nil)
                ForEach(TestType.allCases, id: \.self) { type in
                    filterChip(label: type.displayName, type: type)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func filterChip(label: String, type: TestType?) -> some View {
        let isSelected = filterType == type
        return Button(label) { filterType = type }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.08))
            .foregroundStyle(isSelected ? Color.white : Color.blue)
            .clipShape(Capsule())
    }

    // MARK: - Test Grid

    private var testGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Tests")
                .font(.headline)
                .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(filtered) { test in
                    TestCard(test: test, bestScore: bestScore(for: test.id)) {
                        selectedTest = test
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Attempts")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(attempts.prefix(5)) { attempt in
                AttemptRow(attempt: attempt)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helpers

    private func bestScore(for testId: String) -> Int? {
        attempts.filter { $0.testId == testId }.map(\.score).max()
    }

    private func load() async {
        isLoading = true
        attempts = (try? await FirestoreService.shared.fetchTestAttempts(studentId: profile.id)) ?? []
        isLoading = false
    }
}

// MARK: - Test Card

private struct TestCard: View {
    let test: PracticeTest
    let bestScore: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: test.type.icon)
                        .font(.title3)
                        .foregroundStyle(test.type.color)
                    Spacer()
                    Text(test.type.displayName)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(test.type.color.opacity(0.12))
                        .foregroundStyle(test.type.color)
                        .clipShape(Capsule())
                }

                Text(test.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Label("\(test.questions.count)Q", systemImage: "list.bullet")
                    Label("\(test.timeLimit)m", systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)

                if let score = bestScore {
                    Label("Best: \(score)%", systemImage: "trophy.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(score >= 80 ? .green : score >= 60 ? .orange : .red)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Attempt Row

private struct AttemptRow: View {
    let attempt: TestAttempt

    private var scoreColor: Color {
        attempt.score >= 80 ? .green : attempt.score >= 60 ? .orange : .red
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text("\(attempt.score)%")
                    .font(.caption.bold())
                    .foregroundStyle(scoreColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(attempt.testTitle)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(attempt.correctCount)/\(attempt.totalCount) correct · \(formatTime(attempt.timeTakenSeconds))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(attempt.completedAt.formatted(.relative(presentation: .numeric)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}
