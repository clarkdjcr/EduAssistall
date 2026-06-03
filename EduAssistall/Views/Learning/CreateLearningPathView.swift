import SwiftUI

struct CreateLearningPathView: View {
    let teacherProfile: UserProfile
    var preselectedLink: StudentAdultLink? = nil
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var selectedStudentLink: StudentAdultLink?
    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var pendingItems: [ContentItem] = []
    @State private var showAddItem = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Assignment Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3)
                }

                Section("Assign To Student") {
                    if linkedStudents.isEmpty {
                        Text("No confirmed students found. Students must accept your invite before you can assign paths.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(linkedStudents) { link in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(studentNames[link.studentId] ?? link.studentEmail)
                                        .font(.subheadline)
                                    if studentNames[link.studentId] != nil {
                                        Text(link.studentEmail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
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
                    Text("Approved Content (\(pendingItems.count))")
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Assign Student Path")
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
        let all = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id)) ?? []
        linkedStudents = all.filter(\.confirmed)

        // Pre-select the provided link, or auto-select when there's only one student
        if let pre = preselectedLink {
            selectedStudentLink = linkedStudents.first { $0.id == pre.id }
        } else if linkedStudents.count == 1 {
            selectedStudentLink = linkedStudents.first
        }

        // Load display names in parallel
        var names: [String: String] = [:]
        await withTaskGroup(of: (String, String?).self) { group in
            for link in linkedStudents {
                group.addTask {
                    let profile = try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId)
                    return (link.studentId, profile?.displayName)
                }
            }
            for await (sid, name) in group {
                if let name { names[sid] = name }
            }
        }
        studentNames = names
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
