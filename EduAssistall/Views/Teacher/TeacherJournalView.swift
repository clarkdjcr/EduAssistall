import SwiftUI

/// Private teacher journal — daily reflection that stays owner-only. A teacher can promote any
/// entry into the AI-facing Teaching Wiki via on-device distillation (reviewed before saving).
struct TeacherJournalView: View {
    let teacherProfile: UserProfile

    @State private var entries: [TeacherJournalEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var showCompose = false
    @State private var composeText = ""
    @State private var isSavingEntry = false

    @State private var usedVoice = false

    @State private var distillingId: String?
    @State private var promoteDraft: TeacherWikiEntry?
    @State private var promotingJournalId: String?
    @State private var showPromoteEditor = false

    var body: some View {
        List {
            Section {
                Text("A private space for daily reflection — only you can see it. Promote an insight to your Teaching Wiki when you want the AI to use it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isLoading {
                ProgressView("Loading your journal...")
                    .frame(maxWidth: .infinity)
            } else if entries.isEmpty {
                ContentUnavailableView(
                    "No Journal Entries Yet",
                    systemImage: "note.text",
                    description: Text("Jot down what worked, what didn't, and ideas to revisit.")
                )
            } else {
                Section("Entries") {
                    ForEach(entries) { entry in
                        JournalEntryRow(
                            entry: entry,
                            isDistilling: distillingId == entry.id
                        ) {
                            Task { await promote(entry) }
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
        .navigationTitle("Teaching Journal")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    composeText = ""
                    showCompose = true
                } label: {
                    Label("New Entry", systemImage: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            composeSheet
        }
        .sheet(isPresented: $showPromoteEditor) {
            if let draft = promoteDraft {
                WikiEntryEditorView(teacherId: teacherProfile.id, entry: draft) { saved in
                    markPromoted(journalId: promotingJournalId, wikiId: saved.id)
                }
                .macSheetFrame(width: 700, height: 720)
            }
        }
        .task { await load() }
    }

    private var composeSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What happened in class today…", text: $composeText, axis: .vertical)
                        .lineLimit(8...20)
                    DictationControl(text: $composeText) { usedVoice = true }
                } header: {
                    Text("Reflection")
                } footer: {
                    if JournalDictationService.isSupported {
                        Text("Dictation runs entirely on your device — your voice and words never leave it.")
                    }
                }
            }
            .navigationTitle("New Entry")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCompose = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await saveEntry() } }
                        .disabled(composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSavingEntry)
                }
            }
        }
        .macSheetFrame(width: 640, height: 520)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await FirestoreService.shared.fetchTeacherJournalEntries(teacherId: teacherProfile.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func saveEntry() async {
        isSavingEntry = true
        defer { isSavingEntry = false }
        let entry = TeacherJournalEntry(
            teacherId: teacherProfile.id,
            body: composeText.trimmingCharacters(in: .whitespacesAndNewlines),
            source: usedVoice ? "voice" : "typed"
        )
        do {
            try await FirestoreService.shared.saveTeacherJournalEntry(entry)
            entries.insert(entry, at: 0)
            usedVoice = false
            showCompose = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func promote(_ entry: TeacherJournalEntry) async {
        distillingId = entry.id
        defer { distillingId = nil }
        let draft = await TeacherKnowledgeAIService.shared.distillJournalToWikiDraft(entry, teacherId: teacherProfile.id)
        guard let draft else {
            errorMessage = "Couldn't draft a wiki entry from this reflection. Try editing it manually in the Teaching Wiki."
            return
        }
        promoteDraft = draft
        promotingJournalId = entry.id
        showPromoteEditor = true
    }

    private func markPromoted(journalId: String?, wikiId: String) {
        guard let journalId, let index = entries.firstIndex(where: { $0.id == journalId }) else { return }
        var updated = entries[index]
        updated.promotedToWikiId = wikiId
        updated.updatedAt = Date()
        entries[index] = updated
        Task { try? await FirestoreService.shared.saveTeacherJournalEntry(updated) }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let toDelete = offsets.map { entries[$0] }
        entries.remove(atOffsets: offsets)
        Task {
            for entry in toDelete {
                try? await FirestoreService.shared.deleteTeacherJournalEntry(
                    teacherId: teacherProfile.id,
                    entryId: entry.id
                )
            }
        }
    }
}

// MARK: - Row

private struct JournalEntryRow: View {
    let entry: TeacherJournalEntry
    let isDistilling: Bool
    let onPromote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.createdAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if entry.isPromoted {
                    Label("In Wiki", systemImage: "checkmark.seal.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Text(entry.body)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if !entry.isPromoted {
                Button(action: onPromote) {
                    if isDistilling {
                        HStack(spacing: 6) {
                            ProgressView()
                            Text("Distilling…")
                        }
                    } else {
                        Label("Promote to Wiki", systemImage: "sparkles")
                            .font(.caption.weight(.semibold))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isDistilling)
            }
        }
        .padding(.vertical, 4)
    }
}
