import SwiftUI

struct TeacherLearningPathView: View {
    let teacherProfile: UserProfile

    @State private var paths: [LearningPath] = []
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
                            LearningPathDetailView(path: path, studentId: path.studentId)
                        } label: {
                            TeacherPathRow(path: path)
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
        .navigationTitle("Learning Paths")
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
            Text("No Learning Paths Yet")
                .font(.title3.bold())
            Text("Tap + to create your first learning path and assign it to a student.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showCreate = true
            } label: {
                Label("Create Learning Path", systemImage: "plus.circle.fill")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(path.title)
                .font(.headline)
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
