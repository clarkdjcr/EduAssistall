import SwiftUI

private struct VARKQuestion {
    let text: String
    let options: [VARKOption]
}

private struct VARKOption: Identifiable {
    let id = UUID()
    let text: String
    let style: LearningStyle
}

private let varkQuestions: [VARKQuestion] = [
    VARKQuestion(
        text: "When learning something new, you prefer to:",
        options: [
            VARKOption(text: "Watch a video or see diagrams", style: .visual),
            VARKOption(text: "Listen to an explanation", style: .auditory),
            VARKOption(text: "Try it hands-on yourself", style: .kinesthetic),
            VARKOption(text: "Read instructions or notes", style: .readWrite)
        ]
    ),
    VARKQuestion(
        text: "When you study, you find it most helpful to:",
        options: [
            VARKOption(text: "Look at charts, maps, or colors", style: .visual),
            VARKOption(text: "Talk through ideas with someone", style: .auditory),
            VARKOption(text: "Build or practice something", style: .kinesthetic),
            VARKOption(text: "Write summaries or outlines", style: .readWrite)
        ]
    ),
    VARKQuestion(
        text: "When you need directions to a new place, you prefer:",
        options: [
            VARKOption(text: "A map or visual diagram", style: .visual),
            VARKOption(text: "Someone to explain turn-by-turn", style: .auditory),
            VARKOption(text: "To just start walking and figure it out", style: .kinesthetic),
            VARKOption(text: "Written step-by-step instructions", style: .readWrite)
        ]
    ),
    VARKQuestion(
        text: "When you want to remember something, you:",
        options: [
            VARKOption(text: "Picture it in your mind", style: .visual),
            VARKOption(text: "Say it aloud or make a rhyme", style: .auditory),
            VARKOption(text: "Physically practice or act it out", style: .kinesthetic),
            VARKOption(text: "Write it down repeatedly", style: .readWrite)
        ]
    ),
    VARKQuestion(
        text: "In class, you learn best when the teacher:",
        options: [
            VARKOption(text: "Shows slides, graphs, or visuals", style: .visual),
            VARKOption(text: "Explains and discusses out loud", style: .auditory),
            VARKOption(text: "Has students do activities or labs", style: .kinesthetic),
            VARKOption(text: "Assigns reading and written work", style: .readWrite)
        ]
    ),
    VARKQuestion(
        text: "When you're bored or distracted, it helps to:",
        options: [
            VARKOption(text: "Look at something colorful or visual", style: .visual),
            VARKOption(text: "Listen to music or sounds", style: .auditory),
            VARKOption(text: "Move around, stretch, or fidget", style: .kinesthetic),
            VARKOption(text: "Jot notes or make a to-do list", style: .readWrite)
        ]
    ),
    VARKQuestion(
        text: "When explaining something to a friend, you:",
        options: [
            VARKOption(text: "Draw a picture or diagram", style: .visual),
            VARKOption(text: "Talk it through out loud", style: .auditory),
            VARKOption(text: "Show them or do a demo", style: .kinesthetic),
            VARKOption(text: "Write it out step by step", style: .readWrite)
        ]
    ),
    VARKQuestion(
        text: "You feel most confident after learning when you:",
        options: [
            VARKOption(text: "Can visualize how it all connects", style: .visual),
            VARKOption(text: "Can explain it out loud clearly", style: .auditory),
            VARKOption(text: "Have successfully done it yourself", style: .kinesthetic),
            VARKOption(text: "Have notes you can review later", style: .readWrite)
        ]
    )
]

struct LearningStyleAssessmentView: View {
    @Binding var profile: LearningProfile
    let onComplete: () -> Void

    @State private var currentIndex = 0
    @State private var answers: [LearningStyle] = []

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentIndex), total: Double(varkQuestions.count))
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .tint(.blue)

            Text("Question \(currentIndex + 1) of \(varkQuestions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()

            let question = varkQuestions[currentIndex]

            VStack(spacing: 24) {
                Text(question.text)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    ForEach(question.options) { option in
                        Button {
                            selectOption(option.style)
                        } label: {
                            Text(option.text)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.appSecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .navigationTitle("Learning Style")
        .inlineNavigationTitle()
    }

    private func selectOption(_ style: LearningStyle) {
        answers.append(style)
        if currentIndex < varkQuestions.count - 1 {
            currentIndex += 1
        } else {
            profile.learningStyle = computedStyle()
            onComplete()
        }
    }

    private func computedStyle() -> LearningStyle {
        var counts: [LearningStyle: Int] = [:]
        for answer in answers {
            counts[answer, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? .visual
    }
}
