import SwiftUI

struct GradingSetupView: View {
    let teacherProfile: UserProfile

    @State private var weights = GradeWeights.defaultWeights(teacherId: "")
    @State private var criteria: [GradingCriteria] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showAddCriteria = false
    @State private var saveSuccess = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    WeightSliderRow(label: "Homework", value: $weights.homework, color: .blue)
                    WeightSliderRow(label: "Quizzes",  value: $weights.quizzes,  color: .orange)
                    WeightSliderRow(label: "Group Activities", value: $weights.groupActivities, color: .green)
                    WeightSliderRow(label: "Final Exam", value: $weights.finalExam, color: .purple)

                    Divider()

                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(weights.total))%")
                            .font(.headline.bold())
                            .foregroundStyle(weights.isValid ? .green : .red)
                    }
                }
                .padding(.vertical, 6)
            } header: {
                Text("Grade Weights")
            } footer: {
                Text("Percentages must add up to exactly 100%.")
            }

            Section {
                Button {
                    Task { await saveWeights() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving { ProgressView() }
                        else if saveSuccess {
                            Label("Saved!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Text("Save Grade Weights").fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving || !weights.isValid)
            }

            Section {
                if criteria.isEmpty {
                    Text("No rubrics yet. Tap Add to create one.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(criteria) { c in
                        NavigationLink {
                            EditGradingCriteriaView(criteria: c, teacherId: teacherProfile.id) { updated in
                                if let idx = criteria.firstIndex(where: { $0.id == updated.id }) {
                                    criteria[idx] = updated
                                }
                            }
                        } label: {
                            CriteriaRow(criteria: c)
                        }
                    }
                    .onDelete { offsets in
                        Task { await deleteCriteria(at: offsets) }
                    }
                }
            } header: {
                HStack {
                    Text("Rubrics")
                    Spacer()
                    Button { showAddCriteria = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
        .navigationTitle("Grading Setup")
        .inlineNavigationTitle()
        .sheet(isPresented: $showAddCriteria) {
            EditGradingCriteriaView(criteria: nil, teacherId: teacherProfile.id) { newC in
                criteria.append(newC)
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        async let wFetch = FirestoreService.shared.fetchGradeWeights(teacherId: teacherProfile.id)
        async let cFetch = FirestoreService.shared.fetchGradingCriteria(teacherId: teacherProfile.id)
        if let w = try? await wFetch { weights = w }
        else { weights = GradeWeights.defaultWeights(teacherId: teacherProfile.id) }
        criteria = (try? await cFetch) ?? []
        isLoading = false
    }

    private func saveWeights() async {
        isSaving = true
        saveSuccess = false
        weights.id = teacherProfile.id
        weights.teacherId = teacherProfile.id
        try? await FirestoreService.shared.saveGradeWeights(weights)
        isSaving = false
        saveSuccess = true
        try? await Task.sleep(for: .seconds(2))
        saveSuccess = false
    }

    private func deleteCriteria(at offsets: IndexSet) async {
        for idx in offsets {
            let c = criteria[idx]
            try? await FirestoreService.shared.deleteGradingCriteria(criteriaId: c.id)
        }
        criteria.remove(atOffsets: offsets)
    }
}

// MARK: - Weight Slider Row

private struct WeightSliderRow: View {
    let label: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(value))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                    .frame(width: 44, alignment: .trailing)
            }
            Slider(value: $value, in: 0...100, step: 5)
                .tint(color)
        }
    }
}

// MARK: - Criteria Row

private struct CriteriaRow: View {
    let criteria: GradingCriteria

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: criteria.assignmentType.icon)
                .foregroundStyle(.purple)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(criteria.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(criteria.assignmentType.displayName) · \(criteria.totalPoints) pts · \(criteria.rubricItems.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Edit/Add Criteria Sheet

struct EditGradingCriteriaView: View {
    let criteria: GradingCriteria?    // nil = create new
    let teacherId: String
    let onSave: (GradingCriteria) -> Void

    @State private var title = ""
    @State private var selectedType: AssignmentType = .homework
    @State private var rubric: [RubricItem] = []
    @State private var newCriterion = ""
    @State private var newPoints = 10
    @State private var newDesc = ""
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Rubric Info") {
                    TextField("Title (e.g. Week 3 Homework)", text: $title)
                    Picker("Assignment Type", selection: $selectedType) {
                        ForEach(AssignmentType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }

                Section {
                    if rubric.isEmpty {
                        Text("Add criteria below.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(rubric) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.criterion).font(.subheadline)
                                    if !item.description.isEmpty {
                                        Text(item.description).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text("\(item.maxPoints) pts")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                            }
                        }
                        .onDelete { rubric.remove(atOffsets: $0) }
                    }
                } header: {
                    Text("Rubric Items — Total: \(rubric.reduce(0) { $0 + $1.maxPoints }) pts")
                }

                Section("Add Criterion") {
                    TextField("Criterion name", text: $newCriterion)
                    Stepper("Points: \(newPoints)", value: $newPoints, in: 1...100)
                    TextField("Description (optional)", text: $newDesc)
                    Button("Add Item") {
                        guard !newCriterion.isEmpty else { return }
                        rubric.append(RubricItem(criterion: newCriterion,
                                                 maxPoints: newPoints,
                                                 description: newDesc))
                        newCriterion = ""
                        newPoints = 10
                        newDesc = ""
                    }
                    .disabled(newCriterion.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section {
                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView() }
                            else { Text(criteria == nil ? "Create Rubric" : "Save Changes").fontWeight(.semibold) }
                            Spacer()
                        }
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty || rubric.isEmpty)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .background(Color.appGroupedBackground)
            .navigationTitle(criteria == nil ? "New Rubric" : "Edit Rubric")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: adaptiveTopBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let c = criteria {
                    title = c.title
                    selectedType = c.assignmentType
                    rubric = c.rubricItems
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        var c = criteria ?? GradingCriteria(teacherId: teacherId, title: "", type: selectedType)
        c.title = title.trimmingCharacters(in: .whitespaces)
        c.assignmentType = selectedType
        c.rubricItems = rubric
        if criteria == nil { c.teacherId = teacherId }
        try? await FirestoreService.shared.saveGradingCriteria(c)
        onSave(c)
        isSaving = false
        dismiss()
    }
}
