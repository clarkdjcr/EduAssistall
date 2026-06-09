import SwiftUI

/// Teacher Wiki — personal, reusable teaching knowledge that amplifies AI-generated
/// assignments. Entries flagged "Use in AI generation" are selected by subject/grade/
/// standard and injected as a subordinate enhancement layer when a lesson plan is built.
struct TeacherWikiView: View {
    let teacherProfile: UserProfile

    @State private var entries: [TeacherWikiEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var editingEntry: TeacherWikiEntry?
    @State private var showEditor = false

    var body: some View {
        List {
            Section {
                Text("Capture analogies, hooks, common misconceptions, and what works for your class. Entries marked for AI use enrich your assignments without changing the approved curriculum.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isLoading {
                ProgressView("Loading your wiki...")
                    .frame(maxWidth: .infinity)
            } else if entries.isEmpty {
                ContentUnavailableView(
                    "No Wiki Entries Yet",
                    systemImage: "book.closed",
                    description: Text("Add your first teaching insight to start amplifying your assignments.")
                )
            } else {
                Section("Entries") {
                    ForEach(entries) { entry in
                        Button {
                            editingEntry = entry
                            showEditor = true
                        } label: {
                            WikiEntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
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
        .navigationTitle("Teaching Wiki")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editingEntry = nil
                    showEditor = true
                } label: {
                    Label("Add Entry", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            WikiEntryEditorView(teacherId: teacherProfile.id, entry: editingEntry) { saved in
                upsert(saved)
            }
            .macSheetFrame(width: 700, height: 720)
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await FirestoreService.shared.fetchTeacherWikiEntries(teacherId: teacherProfile.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func upsert(_ entry: TeacherWikiEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
        entries.sort { $0.updatedAt > $1.updatedAt }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let toDelete = offsets.map { entries[$0] }
        entries.remove(atOffsets: offsets)
        Task {
            for entry in toDelete {
                try? await FirestoreService.shared.deleteTeacherWikiEntry(
                    teacherId: teacherProfile.id,
                    entryId: entry.id
                )
            }
        }
    }
}

// MARK: - Row

private struct WikiEntryRow: View {
    let entry: TeacherWikiEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.title.isEmpty ? "Untitled" : entry.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if entry.applyToGeneration {
                    Label("AI", systemImage: "sparkles")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.blue)
                        .labelStyle(.titleAndIcon)
                }
            }
            if !entry.body.isEmpty {
                Text(entry.body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if !metaLine.isEmpty {
                Text(metaLine)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var metaLine: String {
        var parts: [String] = []
        if !entry.subject.isEmpty { parts.append(entry.subject) }
        if !entry.gradeLevel.isEmpty { parts.append("Grade \(entry.gradeLevel)") }
        if !entry.standardCodes.isEmpty { parts.append(entry.standardCodes.joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }
}
