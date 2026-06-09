import SwiftUI

/// Shared editor for creating or editing a `TeacherWikiEntry`. Used both from the Teaching
/// Wiki and from the journal's "Promote to Wiki" flow (where it opens prefilled with an
/// AI-distilled draft for the teacher to review before saving).
struct WikiEntryEditorView: View {
    let teacherId: String
    let entry: TeacherWikiEntry?
    let onSave: (TeacherWikiEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let grades = ["", "K", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    private static let subjects = ["", "ELA", "Math", "Science", "Social Studies", "Art", "Music", "PE", "Technology", "Other"]

    @State private var title: String
    @State private var bodyText: String
    @State private var subject: String
    @State private var gradeLevel: String
    @State private var standardCodesText: String
    @State private var tagsText: String
    @State private var applyToGeneration: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(teacherId: String, entry: TeacherWikiEntry?, onSave: @escaping (TeacherWikiEntry) -> Void) {
        self.teacherId = teacherId
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry?.title ?? "")
        _bodyText = State(initialValue: entry?.body ?? "")
        _subject = State(initialValue: entry?.subject ?? "")
        _gradeLevel = State(initialValue: entry?.gradeLevel ?? "")
        _standardCodesText = State(initialValue: entry?.standardCodes.joined(separator: ", ") ?? "")
        _tagsText = State(initialValue: entry?.tags.joined(separator: ", ") ?? "")
        _applyToGeneration = State(initialValue: entry?.applyToGeneration ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g. Fractions hook that works)", text: $title)
                    TextField("What works — analogy, misconception, pacing, activity…", text: $bodyText, axis: .vertical)
                        .lineLimit(5...12)
                    DictationControl(text: $bodyText)
                } header: {
                    Text("Insight")
                } footer: {
                    if JournalDictationService.isSupported {
                        Text("Dictate the insight on device — your voice never leaves it.")
                    }
                }

                Section("Where it applies") {
                    Picker("Subject", selection: $subject) {
                        ForEach(Self.subjects, id: \.self) { Text($0.isEmpty ? "Any" : $0).tag($0) }
                    }
                    Picker("Grade", selection: $gradeLevel) {
                        ForEach(Self.grades, id: \.self) { Text($0.isEmpty ? "Any" : "Grade \($0)").tag($0) }
                    }
                    TextField("Standards (comma-separated, e.g. 5.NBT.A.1)", text: $standardCodesText)
                    TextField("Tags (comma-separated)", text: $tagsText)
                }

                Section {
                    Toggle("Use in AI generation", isOn: $applyToGeneration)
                } footer: {
                    Text("When on, this insight may shape AI-generated assignments for matching subjects and grades. The approved curriculum always takes precedence.")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        let now = Date()
        let codes = Self.splitList(standardCodesText)
        let tags = Self.splitList(tagsText)
        let saved = TeacherWikiEntry(
            id: entry?.id ?? UUID().uuidString,
            teacherId: teacherId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
            subject: subject,
            gradeLevel: gradeLevel,
            standardCodes: codes,
            tags: tags,
            applyToGeneration: applyToGeneration,
            createdAt: entry?.createdAt ?? now,
            updatedAt: now,
            sourceJournalEntryId: entry?.sourceJournalEntryId
        )
        Task {
            defer { isSaving = false }
            do {
                try await FirestoreService.shared.saveTeacherWikiEntry(saved)
                onSave(saved)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private static func splitList(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
