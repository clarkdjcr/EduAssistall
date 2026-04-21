import SwiftUI

struct GoalSettingView: View {
    let profile: UserProfile

    @State private var goals: [LearningGoal] = []
    @State private var isLoading = true
    @State private var showingAddGoal = false

    private var inProgress: [LearningGoal] { goals.filter { $0.status == .inProgress } }
    private var completed:  [LearningGoal] { goals.filter { $0.status == .completed } }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if goals.isEmpty {
                    emptyState
                } else {
                    goalList
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("My Goals")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddGoal = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(studentId: profile.id) { newGoal in
                    goals.insert(newGoal, at: 0)
                }
            }
        }
        .task { await loadGoals() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 56))
                .foregroundStyle(.blue.opacity(0.5))
            Text("Set your first goal")
                .font(.title3.bold())
            Text("Track what you want to achieve in your learning journey.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            Button {
                showingAddGoal = true
            } label: {
                Text("Add Goal")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Goal List

    private var goalList: some View {
        List {
            if !inProgress.isEmpty {
                Section("In Progress") {
                    ForEach(inProgress) { goal in
                        GoalRow(goal: goal, onComplete: { complete(goal) }, onDelete: { delete(goal) })
                    }
                }
            }
            if !completed.isEmpty {
                Section("Completed") {
                    ForEach(completed) { goal in
                        GoalRow(goal: goal, onComplete: nil, onDelete: { delete(goal) })
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    // MARK: - Actions

    private func loadGoals() async {
        isLoading = true
        goals = (try? await FirestoreService.shared.fetchGoals(studentId: profile.id)) ?? []
        isLoading = false
    }

    private func complete(_ goal: LearningGoal) {
        Task {
            try? await FirestoreService.shared.updateGoalStatus(goalId: goal.id, studentId: profile.id, status: .completed)
            if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[idx].status = .completed
            }
        }
    }

    private func delete(_ goal: LearningGoal) {
        Task {
            try? await FirestoreService.shared.deleteGoal(goalId: goal.id, studentId: profile.id)
            goals.removeAll { $0.id == goal.id }
        }
    }
}

// MARK: - Goal Row

private struct GoalRow: View {
    let goal: LearningGoal
    let onComplete: (() -> Void)?
    let onDelete: () -> Void

    private var formattedDate: String? {
        guard let date = goal.targetDate else { return nil }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(goal.title)
                .font(.subheadline.bold())
                .strikethrough(goal.status == .completed, color: .secondary)
                .foregroundStyle(goal.status == .completed ? .secondary : .primary)

            HStack(spacing: 10) {
                if let subject = goal.subject {
                    Text(subject)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                if let date = formattedDate {
                    Label(date, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if let complete = onComplete {
                Button { complete() } label: {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)
            }
        }
    }
}

// MARK: - Add Goal Sheet

private struct AddGoalView: View {
    let studentId: String
    let onSave: (LearningGoal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var subject: String? = nil
    @State private var hasTargetDate = false
    @State private var targetDate = Date().addingTimeInterval(7 * 86_400)
    @State private var isSaving = false

    private let subjects = ["Math", "Science", "Computing", "History", "English", "Economics", "Art"]

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("e.g. Master fractions", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Details") {
                    Picker("Subject", selection: $subject) {
                        Text("None").tag(Optional<String>.none)
                        ForEach(subjects, id: \.self) { s in
                            Text(s).tag(Optional(s))
                        }
                    }

                    Toggle("Target Date", isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker("Date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("New Goal")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid || isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        let goal = LearningGoal(
            studentId: studentId,
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes,
            subject: subject,
            targetDate: hasTargetDate ? targetDate : nil
        )
        Task {
            try? await FirestoreService.shared.saveGoal(goal)
            onSave(goal)
            dismiss()
        }
    }
}
