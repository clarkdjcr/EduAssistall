import SwiftUI

struct GradeAssignmentSheet: View {
    let assignment: WeeklyAssignment
    let teacherId: String
    let existingGrade: StudentGrade?
    let onSave: (StudentGrade) -> Void

    @State private var scoreText: String
    @State private var feedback: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(assignment: WeeklyAssignment, teacherId: String,
         existingGrade: StudentGrade?, onSave: @escaping (StudentGrade) -> Void) {
        self.assignment = assignment
        self.teacherId = teacherId
        self.existingGrade = existingGrade
        self.onSave = onSave
        _scoreText = State(initialValue: existingGrade.map { String(format: "%.0f", $0.score) } ?? "")
        _feedback  = State(initialValue: existingGrade?.feedback ?? "")
    }

    private var parsedScore: Double? {
        guard let v = Double(scoreText.trimmingCharacters(in: .whitespaces)),
              v >= 0, v <= 100 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment") {
                    Text(assignment.title)
                        .font(.subheadline)
                    Label(assignment.dayLabel, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                Section {
                    HStack {
                        Text("Score (0 – 100)")
                        Spacer()
                        TextField("e.g. 85", text: $scoreText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    if let score = parsedScore {
                        HStack {
                            Text("Letter Grade")
                            Spacer()
                            Text(letterGrade(for: score))
                                .font(.headline.bold())
                                .foregroundStyle(gradeColor(for: score))
                        }
                    }
                } header: {
                    Text("Grade")
                }

                Section("Feedback") {
                    TextField("Written feedback for the student…", text: $feedback, axis: .vertical)
                        .lineLimit(4...8)
                }

                if let msg = errorMessage {
                    Section {
                        Label(msg, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .navigationTitle(existingGrade == nil ? "Add Grade" : "Edit Grade")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: adaptiveTopBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: adaptiveTopBarTrailing) {
                    Button("Save") { Task { await save() } }
                        .fontWeight(.semibold)
                        .disabled(parsedScore == nil || isSaving)
                }
            }
        }
    }

    private func save() async {
        guard let score = parsedScore else { return }
        isSaving = true
        errorMessage = nil
        let grade = StudentGrade(
            id: assignment.id,
            assignmentId: assignment.id,
            studentId: assignment.studentId,
            teacherId: teacherId,
            score: score,
            feedback: feedback.trimmingCharacters(in: .whitespacesAndNewlines),
            gradedAt: Date(),
            assignmentTitle: assignment.title
        )
        do {
            try await FirestoreService.shared.saveStudentGrade(grade)
            onSave(grade)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func letterGrade(for score: Double) -> String {
        switch score {
        case 90...:   return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default:      return "F"
        }
    }

    private func gradeColor(for score: Double) -> Color {
        switch score {
        case 90...:   return .green
        case 80..<90: return .blue
        case 70..<80: return .yellow
        case 60..<70: return .orange
        default:      return .red
        }
    }
}
