import SwiftUI

struct TeacherLearningPathView: View {
    let teacherProfile: UserProfile

    @State private var paths: [LearningPath] = []
    @State private var studentNames: [String: String] = [:]
    @State private var isLoading = true
    @State private var showCreate = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if paths.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(paths) { path in
                        NavigationLink {
                            LearningPathDetailView(
                                path: path,
                                studentId: path.studentId,
                                showAnswerModeToggle: true   // FR-006: teachers can toggle answer mode
                            )
                        } label: {
                            TeacherPathRow(path: path, studentName: studentNames[path.studentId])
                        }
                    }
                    .onDelete(perform: deletePaths)
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Assign Paths")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateLearningPathView(teacherProfile: teacherProfile) {
                Task { await load() }
            }
        }
        .task { await load() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No Assigned Paths Yet")
                .font(.title3.bold())
            Text("Start with a lesson plan, then assign approved content as a student path.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showCreate = true
            } label: {
                Label("Assign Student Path", systemImage: "plus.circle.fill")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        paths = (try? await FirestoreService.shared
            .fetchLearningPathsCreatedBy(teacherId: teacherProfile.id)) ?? []
        paths.sort { $0.createdAt > $1.createdAt }

        // Load display names for all students referenced by these paths
        let uniqueStudentIds = Array(Set(paths.map(\.studentId)))
        var names: [String: String] = [:]
        await withTaskGroup(of: (String, String?).self) { group in
            for sid in uniqueStudentIds {
                group.addTask {
                    let profile = try? await FirestoreService.shared.fetchUserProfile(uid: sid)
                    return (sid, profile?.displayName)
                }
            }
            for await (sid, name) in group {
                if let name { names[sid] = name }
            }
        }
        studentNames = names
        isLoading = false
    }

    private func deletePaths(at offsets: IndexSet) {
        let toDelete = offsets.map { paths[$0] }
        paths.remove(atOffsets: offsets)
        Task {
            for path in toDelete {
                try? await FirestoreService.shared.deleteLearningPath(id: path.id)
            }
        }
    }
}

// MARK: - Teacher Path Row

private struct TeacherPathRow: View {
    let path: LearningPath
    let studentName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(path.title)
                .font(.headline)
            if let name = studentName {
                Label(name, systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            HStack(spacing: 8) {
                Label("\(path.items.count) items", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Label(path.isActive ? "Active" : "Inactive", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(path.isActive ? .green : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
