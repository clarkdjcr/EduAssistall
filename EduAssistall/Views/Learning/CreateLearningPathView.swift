import SwiftUI

struct CreateLearningPathView: View {
    let teacherProfile: UserProfile
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var selectedStudentLink: StudentAdultLink?
    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var pendingItems: [ContentItem] = []
    @State private var showAddItem = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Path Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Assign To Student") {
                    if linkedStudents.isEmpty {
                        Text("No linked students found. Link students from your dashboard first.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(linkedStudents) { link in
                            HStack {
                                Text(link.studentEmail)
                                Spacer()
                                if selectedStudentLink?.id == link.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedStudentLink = link }
                        }
                    }
                }

                Section {
                    ForEach(pendingItems) { item in
                        ContentItemDraftRow(item: item)
                    }
                    .onDelete { offsets in
                        pendingItems.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        pendingItems.move(fromOffsets: from, toOffset: to)
                    }

                    Button {
                        showAddItem = true
                    } label: {
                        Label("Add Content Item", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Content Items (\(pendingItems.count))")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Learning Path")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave || isSaving)
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddContentItemView(teacherId: teacherProfile.id) { newItem in
                    pendingItems.append(newItem)
                }
            }
            .task { await loadStudents() }
        }
    }

    private var canSave: Bool {
        !title.isEmpty && selectedStudentLink != nil && !pendingItems.isEmpty
    }

    private func loadStudents() async {
        linkedStudents = (try? await FirestoreService.shared
            .fetchLinkedStudents(adultId: teacherProfile.id)) ?? []
    }

    private func save() async {
        guard let studentLink = selectedStudentLink else { return }
        isSaving = true
        errorMessage = nil

        do {
            // Save all content items first
            for item in pendingItems {
                try await FirestoreService.shared.saveContentItem(item)
            }

            // Build path with ordered items
            var path = LearningPath(
                title: title,
                description: description,
                studentId: studentLink.studentId,
                createdBy: teacherProfile.id
            )
            path.items = pendingItems.enumerated().map { index, item in
                LearningPathItem(contentItemId: item.id, order: index)
            }

            try await FirestoreService.shared.saveLearningPath(path)
            onSaved()
            dismiss()
        } catch {
            errorMessage = "Failed to save. Please try again."
        }
        isSaving = false
    }
}

// MARK: - Draft Item Row

private struct ContentItemDraftRow: View {
    let item: ContentItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.contentType.icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                Text("\(item.contentType.displayName) · \(item.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
