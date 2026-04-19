import SwiftUI

struct QuizView: View {
    let item: ContentItem
    let studentId: String
    let onProgressUpdated: (StudentProgress) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var correctCount = 0
    @State private var isLoading = true
    @State private var showResult = false
    @State private var isSaving = false

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    private var scorePercent: Int {
        guard !questions.isEmpty else { return 0 }
        return Int(Double(correctCount) / Double(questions.count) * 100)
    }

    private var passed: Bool { scorePercent >= 70 }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading quiz…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if questions.isEmpty {
                emptyState
            } else if showResult {
                resultScreen
            } else if let q = currentQuestion {
                questionScreen(q)
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(item.title)
        .inlineNavigationTitle()
        .task { await load() }
    }

    // MARK: - Question Screen

    private func questionScreen(_ q: QuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Progress indicator
                HStack {
                    Text("Question \(currentIndex + 1) of \(questions.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(correctCount) correct")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue.opacity(0.12))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue)
                            .frame(
                                width: geo.size.width * Double(currentIndex) / Double(questions.count),
                                height: 4
                            )
                    }
                }
                .frame(height: 4)

                // Question text
                Text(q.question)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)

                // Answer options
                VStack(spacing: 10) {
                    ForEach(Array(q.options.enumerated()), id: \.offset) { index, option in
                        AnswerButton(
                            text: option,
                            index: index,
                            selectedAnswer: selectedAnswer,
                            correctIndex: q.correctIndex,
                            onSelect: { handleAnswer(index, correct: q.correctIndex) }
                        )
                    }
                }

                // Explanation (shown after answer)
                if selectedAnswer != nil && !q.explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Explanation", systemImage: "lightbulb.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                        Text(q.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Next button
                if selectedAnswer != nil {
                    Button {
                        advance()
                    } label: {
                        Text(currentIndex + 1 < questions.count ? "Next Question" : "See Results")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Spacer(minLength: 32)
            }
            .padding(20)
        }
    }

    // MARK: - Result Screen

    private var resultScreen: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: passed ? "checkmark.seal.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(passed ? Color.green : Color.orange)

            VStack(spacing: 8) {
                Text(passed ? "Great Job!" : "Keep Practicing!")
                    .font(.title.bold())
                Text("You scored \(scorePercent)% (\(correctCount) of \(questions.count) correct)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if passed {
                Label("Marked as complete", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }

            VStack(spacing: 12) {
                if !passed {
                    Button {
                        restartQuiz()
                    } label: {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appSecondaryGroupedBackground)
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.appGroupedBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("No Questions Yet")
                .font(.title3.bold())
            Text("Your teacher hasn't added questions to this quiz yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Go Back") { dismiss() }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Logic

    private func handleAnswer(_ index: Int, correct: Int) {
        guard selectedAnswer == nil else { return }
        selectedAnswer = index
        if index == correct { correctCount += 1 }
    }

    private func advance() {
        selectedAnswer = nil
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            finishQuiz()
        }
    }

    private func restartQuiz() {
        currentIndex = 0
        correctCount = 0
        selectedAnswer = nil
        showResult = false
    }

    private func finishQuiz() {
        showResult = true
        Task { await saveResults() }
    }

    private func saveResults() async {
        isSaving = true
        let attempt = QuizAttempt(
            studentId: studentId,
            contentItemId: item.id,
            correctCount: correctCount,
            totalCount: questions.count
        )
        try? await FirestoreService.shared.saveQuizAttempt(attempt)

        // Award perfect quiz badge
        if scorePercent == 100 {
            try? await FirestoreService.shared.awardBadge(studentId: studentId, type: .perfectQuiz)
        }

        // Mark complete if passing score
        if passed {
            var progress = StudentProgress(studentId: studentId, contentItemId: item.id)
            progress.markComplete()
            try? await FirestoreService.shared.saveProgress(progress)
            onProgressUpdated(progress)
            await FirestoreService.shared.checkAndAwardBadges(studentId: studentId)
        }
        isSaving = false
    }

    private func load() async {
        isLoading = true
        questions = (try? await FirestoreService.shared.fetchQuizQuestions(contentItemId: item.id)) ?? []
        isLoading = false
    }
}

// MARK: - Answer Button

private struct AnswerButton: View {
    let text: String
    let index: Int
    let selectedAnswer: Int?
    let correctIndex: Int
    let onSelect: () -> Void

    private var isSelected: Bool { selectedAnswer == index }
    private var isAnswered: Bool { selectedAnswer != nil }
    private var isCorrect: Bool { index == correctIndex }

    private var background: Color {
        guard isAnswered else { return Color.appSecondaryGroupedBackground }
        if isCorrect { return Color.green.opacity(0.15) }
        if isSelected { return Color.red.opacity(0.15) }
        return Color.appSecondaryGroupedBackground
    }

    private var borderColor: Color {
        guard isAnswered else { return Color.clear }
        if isCorrect { return Color.green }
        if isSelected { return Color.red }
        return Color.clear
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(["A", "B", "C", "D"][safe: index] ?? "")
                    .font(.caption.bold())
                    .frame(width: 26, height: 26)
                    .background(isAnswered && isCorrect ? Color.green : Color.blue.opacity(0.12))
                    .foregroundStyle(isAnswered && isCorrect ? Color.white : Color.blue)
                    .clipShape(Circle())

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isAnswered {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    } else if isSelected {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    }
                }
            }
            .padding(14)
            .background(background)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isAnswered)
    }
}

