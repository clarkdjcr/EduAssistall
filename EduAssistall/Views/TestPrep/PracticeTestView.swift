import SwiftUI

struct PracticeTestView: View {
    let test: PracticeTest
    let studentId: String
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var activeTest: PracticeTest
    @State private var currentIndex = 0
    @State private var selectedAnswers: [Int]
    @State private var secondsRemaining: Int
    @State private var isSubmitted = false
    @State private var attempt: TestAttempt?
    @State private var startTime = Date()
    @State private var timerVersion = 0

    init(test: PracticeTest, studentId: String, onComplete: @escaping () -> Void) {
        self.test = test
        self.studentId = studentId
        self.onComplete = onComplete
        let shuffled = Self.shuffled(test)
        self._activeTest = State(initialValue: shuffled)
        self._selectedAnswers = State(initialValue: Array(repeating: -1, count: shuffled.questions.count))
        self._secondsRemaining = State(initialValue: test.timeLimit * 60)
    }

    private var currentQuestion: PracticeTestQuestion { activeTest.questions[currentIndex] }
    private var answeredCount: Int { selectedAnswers.filter { $0 >= 0 }.count }
    private var allAnswered: Bool { answeredCount == activeTest.questions.count }

    var body: some View {
        Group {
            if isSubmitted, let attempt {
                TestResultsView(test: activeTest, attempt: attempt, onDone: {
                    onComplete()
                    dismiss()
                }, onRetake: {
                    reset()
                })
            } else {
                testContent
            }
        }
    }

    // MARK: - Test Content

    private var testContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        questionText
                        answerOptions
                        Spacer(minLength: 32)
                    }
                    .padding(20)
                }
                navigationFooter
            }
            .background(Color.appGroupedBackground)
            .navigationTitle(test.title)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    timerLabel
                }
            }
            .task(id: timerVersion) { await runTimer() }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(currentIndex + 1) of \(activeTest.questions.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(answeredCount) answered")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.blue.opacity(0.1)).frame(height: 3)
                    RoundedRectangle(cornerRadius: 2).fill(Color.blue)
                        .frame(width: geo.size.width * Double(currentIndex) / Double(activeTest.questions.count), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.appSecondaryGroupedBackground)
    }

    // MARK: - Question

    private var questionText: some View {
        Text(currentQuestion.question)
            .font(.title3.bold())
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Answer Options

    private var answerOptions: some View {
        let labels = ["A", "B", "C", "D"]
        return VStack(spacing: 10) {
            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { idx, option in
                let isSelected = selectedAnswers[currentIndex] == idx
                Button {
                    selectedAnswers[currentIndex] = idx
                } label: {
                    HStack(spacing: 12) {
                        Text(labels[safe: idx] ?? "")
                            .font(.caption.bold())
                            .frame(width: 26, height: 26)
                            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                            .foregroundStyle(isSelected ? Color.white : Color.blue)
                            .clipShape(Circle())
                        Text(option)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                        }
                    }
                    .padding(14)
                    .background(isSelected ? Color.blue.opacity(0.08) : Color.appSecondaryGroupedBackground)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Navigation Footer

    private var navigationFooter: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(activeTest.questions.indices, id: \.self) { i in
                        Button { currentIndex = i } label: {
                            Circle()
                                .fill(selectedAnswers[i] >= 0 ? Color.green : (i == currentIndex ? Color.blue : Color.gray.opacity(0.3)))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            HStack(spacing: 12) {
                Button {
                    if currentIndex > 0 { currentIndex -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .frame(width: 44, height: 44)
                        .background(Color.appSecondaryGroupedBackground)
                        .clipShape(Circle())
                }
                .disabled(currentIndex == 0)

                Button {
                    if currentIndex + 1 < activeTest.questions.count {
                        currentIndex += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .frame(width: 44, height: 44)
                        .background(Color.appSecondaryGroupedBackground)
                        .clipShape(Circle())
                }
                .disabled(currentIndex + 1 >= activeTest.questions.count)

                Spacer()

                Button {
                    submitTest()
                } label: {
                    Text(allAnswered ? "Submit Test" : "Submit (\(answeredCount)/\(activeTest.questions.count))")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(allAnswered ? Color.green : Color.blue)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(Color.appGroupedBackground)
    }

    // MARK: - Timer

    private var timerLabel: some View {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        let isLow = secondsRemaining < 60
        return Label(String(format: "%d:%02d", m, s), systemImage: "clock")
            .font(.subheadline.bold())
            .foregroundStyle(isLow ? Color.red : Color.primary)
    }

    private func runTimer() async {
        while secondsRemaining > 0 && !isSubmitted {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if !isSubmitted { secondsRemaining -= 1 }
        }
        if !isSubmitted { submitTest() }
    }

    private func submitTest() {
        guard !isSubmitted else { return }
        isSubmitted = true
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let a = TestAttempt(studentId: studentId, test: activeTest, answers: selectedAnswers, timeTakenSeconds: elapsed)
        attempt = a
        Task { try? await FirestoreService.shared.saveTestAttempt(a) }
    }

    // MARK: - Retake

    private func reset() {
        let reshuffled = Self.shuffled(test)
        activeTest = reshuffled
        currentIndex = 0
        selectedAnswers = Array(repeating: -1, count: reshuffled.questions.count)
        secondsRemaining = test.timeLimit * 60
        isSubmitted = false
        attempt = nil
        startTime = Date()
        timerVersion += 1
    }

    // Shuffles question order and answer option order, keeping correctIndex in sync.
    private static func shuffled(_ test: PracticeTest) -> PracticeTest {
        var t = test
        t.questions = test.questions.shuffled().map { q in
            var sq = q
            let indices = Array(q.options.indices).shuffled()
            sq.options = indices.map { q.options[$0] }
            sq.correctIndex = indices.firstIndex(of: q.correctIndex) ?? q.correctIndex
            return sq
        }
        return t
    }
}
