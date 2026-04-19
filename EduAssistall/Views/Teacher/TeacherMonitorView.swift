import SwiftUI

struct TeacherMonitorView: View {
    let teacherProfile: UserProfile

    @State private var students: [StudentAdultLink] = []
    @State private var progressSummaries: [String: (completed: Int, total: Int)] = [:]
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if students.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(students) { link in
                            NavigationLink {
                                StudentProgressDetailView(
                                    studentId: link.studentId,
                                    studentEmail: link.studentEmail
                                )
                            } label: {
                                MonitorStudentRow(
                                    link: link,
                                    summary: progressSummaries[link.studentId]
                                )
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Monitor")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Students Yet")
                .font(.title3.bold())
            Text("Link students to your class to monitor their progress here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        let linked = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id)) ?? []
        students = linked.filter { $0.confirmed }

        // Fetch progress summaries for all students concurrently
        await withTaskGroup(of: (String, Int, Int).self) { group in
            for link in students {
                group.addTask {
                    async let fetchPaths = FirestoreService.shared.fetchAllLearningPaths(studentId: link.studentId)
                    async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: link.studentId)

                    let paths = (try? await fetchPaths) ?? []
                    let progressList = (try? await fetchProgress) ?? []
                    let progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })

                    let allItems = paths.flatMap(\.items)
                    let total = allItems.count
                    let completed = allItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
                    return (link.studentId, completed, total)
                }
            }
            for await (studentId, completed, total) in group {
                progressSummaries[studentId] = (completed, total)
            }
        }

        isLoading = false
    }
}

// MARK: - Monitor Student Row

private struct MonitorStudentRow: View {
    let link: StudentAdultLink
    let summary: (completed: Int, total: Int)?

    private var fraction: Double {
        guard let s = summary, s.total > 0 else { return 0 }
        return Double(s.completed) / Double(s.total)
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(link.studentEmail.prefix(1)).uppercased())
                        .font(.headline.bold())
                        .foregroundStyle(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(link.studentEmail)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                if let s = summary {
                    Text("\(s.completed) of \(s.total) lessons done")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.blue.opacity(0.12))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(fraction == 1.0 ? Color.green : Color.blue)
                                .frame(width: geo.size.width * fraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                } else {
                    Text("No paths assigned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
