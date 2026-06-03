import SwiftUI

struct GenerateLessonPlanView: View {
    let teacherProfile: UserProfile

    private static let grades   = ["K","1","2","3","4","5","6","7","8","9","10","11","12"]
    private static let subjects = ["ELA","Math","Science","Social Studies","Art","Music","PE","Technology","Other"]
    private static let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri"]

    @State private var grade           = "5"
    @State private var subject         = "Math"
    @State private var topic           = ""
    @State private var standard        = ""
    @State private var durationMinutes = 45
    @State private var startDate       = Date()
    @State private var endDate         = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
    @State private var selectedWeekdays = Set(Self.weekdays)
    @State private var supplementalResources = ""
    @State private var teacherNotes    = ""
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

                Section("Teaching Window") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Class Meets")
                            .font(.subheadline)
                        WeekdaySelector(selectedWeekdays: $selectedWeekdays, weekdays: Self.weekdays)
                        Text("\(availableTeachingDays) teaching day\(availableTeachingDays == 1 ? "" : "s") available")
                            .font(.caption)
                            .foregroundStyle(availableTeachingDays == 0 ? .red : .secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    TextField("Videos, articles, current events, or links", text: $supplementalResources, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Teacher notes, pacing constraints, or class context", text: $teacherNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Amplifying Sources")
                } footer: {
                    Text("EduAssist will ground the plan in approved curriculum first, then use these teacher-approved sources only as supporting material.")
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
                    .disabled(topic.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating || availableTeachingDays == 0)
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
                        documentId: result.documentId,
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
                    standard: standard.trimmingCharacters(in: .whitespaces),
                    startDate: startDate,
                    endDate: endDate,
                    teachingDays: Self.weekdays.filter { selectedWeekdays.contains($0) },
                    supplementalResources: supplementalResources.trimmingCharacters(in: .whitespacesAndNewlines),
                    teacherNotes: teacherNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                showResult = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var availableTeachingDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return 0 }

        var count = 0
        var current = start
        while current <= end {
            let weekday = calendar.component(.weekday, from: current)
            let label = weekdayLabel(for: weekday)
            if selectedWeekdays.contains(label) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return count
    }

    private func weekdayLabel(for weekday: Int) -> String {
        switch weekday {
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        default: return ""
        }
    }
}

private struct WeekdaySelector: View {
    @Binding var selectedWeekdays: Set<String>
    let weekdays: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekdays, id: \.self) { weekday in
                Button {
                    if selectedWeekdays.contains(weekday) {
                        selectedWeekdays.remove(weekday)
                    } else {
                        selectedWeekdays.insert(weekday)
                    }
                } label: {
                    Text(weekday)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedWeekdays.contains(weekday) ? Color.blue : Color.appSecondaryBackground)
                        .foregroundStyle(selectedWeekdays.contains(weekday) ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
