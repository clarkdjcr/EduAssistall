import SwiftUI

struct GenerateLessonPlanView: View {
    let teacherProfile: UserProfile

    private static let grades   = ["K","1","2","3","4","5","6","7","8","9","10","11","12"]
    private static let subjects = ["ELA","Math","Science","Social Studies","Art","Music","PE","Technology","Other"]

    @State private var grade           = "5"
    @State private var subject         = "Math"
    @State private var topic           = ""
    @State private var standard        = ""
    @State private var durationMinutes = 45
    @State private var isGenerating    = false
    @State private var result: CloudFunctionService.LessonPlanResult?
    @State private var errorMessage: String?
    @State private var showResult      = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Lesson Details") {
                    Picker("Grade", selection: $grade) {
                        ForEach(Self.grades, id: \.self) { Text("Grade \($0)").tag($0) }
                    }
                    Picker("Subject", selection: $subject) {
                        ForEach(Self.subjects, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Topic (e.g. Place Value, Cell Division)", text: $topic)
                        .nameInput()
                    TextField("Standard (optional, e.g. 5.NBT.A.1)", text: $standard)
                        .nameInput()
                }

                Section("Duration") {
                    Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 30...90, step: 5)
                }

                if let msg = errorMessage {
                    Section {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                Section {
                    Button(action: generate) {
                        if isGenerating {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white)
                                Text("Generating…")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Generate Lesson Plan", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(topic.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .navigationTitle("Lesson Plan")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showResult) {
                if let result {
                    DocumentResultView(
                        title: "Lesson Plan — \(subject) Grade \(grade)",
                        content: result.lessonPlan,
                        sharepointItemId: result.sharepointItemId,
                        documentType: "lesson plan"
                    )
                }
            }
        }
    }

    private func generate() {
        errorMessage = nil
        isGenerating = true
        Task {
            defer { isGenerating = false }
            do {
                result = try await CloudFunctionService.shared.generateLessonPlan(
                    grade: grade,
                    subject: subject,
                    topic: topic.trimmingCharacters(in: .whitespaces),
                    durationMinutes: durationMinutes,
                    standard: standard.trimmingCharacters(in: .whitespaces)
                )
                showResult = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
