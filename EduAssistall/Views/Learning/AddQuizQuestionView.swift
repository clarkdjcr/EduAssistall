import SwiftUI

// MARK: - Manage Quiz Questions (teacher entry point)

struct ManageQuizQuestionsView: View {
    let item: ContentItem
    let teacherId: String
    let onDone: () -> Void

    @State private var questions: [QuizQuestion] = []
    @State private var isLoading = true
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section(header: Text("\(questions.count) question\(questions.count == 1 ? "" : "s")")) {
                            if questions.isEmpty {
                                Text("No questions yet — tap + to add one.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(questions) { q in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(q.question)
                                            .font(.subheadline.bold())
                                        if let correct = q.options[safe: q.correctIndex] {
                                            Label(correct, systemImage: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onDelete(perform: deleteQuestions)
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Quiz Questions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddQuizQuestionView(
                    contentItemId: item.id,
                    teacherId: teacherId,
                    order: questions.count
                ) {
                    Task { await load() }
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        questions = (try? await FirestoreService.shared.fetchQuizQuestions(contentItemId: item.id)) ?? []
        isLoading = false
    }

    private func deleteQuestions(at offsets: IndexSet) {
        let toDelete = offsets.map { questions[$0] }
        questions.remove(atOffsets: offsets)
        Task {
            for q in toDelete {
                try? await FirestoreService.shared.deleteQuizQuestion(id: q.id)
            }
        }
    }
}

// MARK: - Add Quiz Question

struct AddQuizQuestionView: View {
    let contentItemId: String
    let teacherId: String
    let order: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var questionText = ""
    @State private var options = ["", "", "", ""]
    @State private var correctIndex = 0
    @State private var explanation = ""
    @State private var isSaving = false

    private let labels = ["A", "B", "C", "D"]

    private var isValid: Bool {
        !questionText.isEmpty && options.allSatisfy { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question") {
                    TextField("Enter your question", text: $questionText, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section("Answer Options") {
                    ForEach(0..<4, id: \.self) { i in
                        HStack(spacing: 10) {
                            Text(labels[i])
                                .font(.caption.bold())
                                .frame(width: 20)
                                .foregroundStyle(.blue)
                            TextField("Option \(labels[i])", text: $options[i])
                        }
                    }
                }

                Section("Correct Answer") {
                    Picker("Correct Answer", selection: $correctIndex) {
                        ForEach(0..<4, id: \.self) { i in
                            let label = options[i].isEmpty ? "(empty)" : options[i]
                            Text("\(labels[i]): \(label)").tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Explanation (Optional)") {
                    TextField("Why is this the correct answer?", text: $explanation, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Question")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .fontWeight(.semibold)
                            .disabled(!isValid)
                    }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let q = QuizQuestion(
            contentItemId: contentItemId,
            question: questionText,
            options: options,
            correctIndex: correctIndex,
            explanation: explanation,
            order: order,
            createdBy: teacherId
        )
        try? await FirestoreService.shared.saveQuizQuestion(q)
        onSave()
        dismiss()
        isSaving = false
    }
}

// Safe subscript helper (shared across Learning views)
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
