import SwiftUI

struct TestResultsView: View {
    let test: PracticeTest
    let attempt: TestAttempt
    let onDone: () -> Void

    @State private var expandedQuestion: String?

    private var scoreColor: Color {
        attempt.score >= 80 ? .green : attempt.score >= 60 ? .orange : .red
    }

    private var scoreLabel: String {
        attempt.score >= 80 ? "Great Work!" : attempt.score >= 60 ? "Good Effort!" : "Keep Practicing!"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scoreHero
                    statsRow
                    questionBreakdown
                    if hasMissedStandards { standardsSection }
                    Spacer(minLength: 32)
                }
                .padding(.vertical, 16)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Results")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Score Hero

    private var scoreHero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 14)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: Double(attempt.score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 0.8), value: attempt.score)
                Text("\(attempt.score)%")
                    .font(.title.bold())
                    .foregroundStyle(scoreColor)
            }
            Text(scoreLabel)
                .font(.title2.bold())
            Text(test.title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            ResultStat(value: "\(attempt.correctCount)/\(attempt.totalCount)", label: "Correct", color: .green)
            ResultStat(value: formatTime(attempt.timeTakenSeconds), label: "Time", color: .blue)
            ResultStat(value: "\(test.timeLimit)m limit", label: "Time Limit", color: .secondary)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Question Breakdown

    private var questionBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Question Breakdown")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(Array(test.questions.enumerated()), id: \.element.id) { idx, q in
                let userAnswer = attempt.answers[safe: idx] ?? -1
                let isCorrect = userAnswer == q.correctIndex
                let isExpanded = expandedQuestion == q.id

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedQuestion = isExpanded ? nil : q.id
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isCorrect ? .green : .red)
                            Text("Q\(idx + 1): \(q.question)")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(isExpanded ? nil : 1)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)

                        if isExpanded {
                            Divider().padding(.horizontal, 14)
                            VStack(alignment: .leading, spacing: 8) {
                                answerLine(label: "Your answer",
                                           text: q.options[safe: userAnswer] ?? "Not answered",
                                           color: isCorrect ? .green : .red)
                                if !isCorrect {
                                    answerLine(label: "Correct answer",
                                               text: q.options[safe: q.correctIndex] ?? "",
                                               color: .green)
                                }
                                if !q.explanation.isEmpty {
                                    Text(q.explanation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if let code = q.standardCode, let std = TestDataProvider.standard(for: code) {
                                    Label("\(std.code): \(std.description)", systemImage: "tag.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(14)
                        }
                    }
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Standards Section

    private var hasMissedStandards: Bool {
        missedStandards.isEmpty == false
    }

    private var missedStandards: [Standard] {
        let missed = zip(attempt.answers, test.questions)
            .filter { $0.0 != $0.1.correctIndex }
            .compactMap { $0.1.standardCode }
        return missed.compactMap { TestDataProvider.standard(for: $0) }
    }

    private var standardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standards to Review")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(missedStandards) { std in
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(std.code)
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        Text(std.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Helpers

    private func answerLine(label: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label + ":")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(color)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m)m" : "\(m)m \(s)s"
    }
}

// MARK: - Result Stat

private struct ResultStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
