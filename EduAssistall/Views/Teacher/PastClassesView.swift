import SwiftUI

struct PastClassesView: View {
    let teacherProfile: UserProfile

    @State private var archivedLinks: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var isLoading = true

    // Group by school year, newest first.
    private var byYear: [(year: String, links: [StudentAdultLink])] {
        let grouped = Dictionary(grouping: archivedLinks) { $0.schoolYear ?? "Unknown" }
        return grouped
            .map { (year: $0.key, links: $0.value.sorted { $0.studentEmail < $1.studentEmail }) }
            .sorted { $0.year > $1.year }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if archivedLinks.isEmpty {
                ContentUnavailableView(
                    "No Past Classes",
                    systemImage: "archivebox",
                    description: Text("Archived classes will appear here after you end a school year.")
                )
            } else {
                List {
                    ForEach(byYear, id: \.year) { group in
                        Section(group.year) {
                            ForEach(group.links) { link in
                                ArchivedStudentNavRow(
                                    link: link,
                                    displayName: displayName(for: link)
                                )
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
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Past Classes")
        .inlineNavigationTitle()
        .task { await load() }
        .refreshable { await load() }
    }

    private func displayName(for link: StudentAdultLink) -> String {
        studentNames[link.studentId] ?? link.studentEmail
    }

    private func load() async {
        isLoading = true
        archivedLinks = (try? await FirestoreService.shared.fetchArchivedLinks(teacherId: teacherProfile.id)) ?? []

        await withTaskGroup(of: Void.self) { group in
            for link in archivedLinks {
                group.addTask {
                    let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId))?.displayName
                    await MainActor.run {
                        if let name { studentNames[link.studentId] = name }
                    }
                }
            }
        }
        isLoading = false
    }
}

private struct ArchivedStudentNavRow: View {
    let link: StudentAdultLink
    let displayName: String

    var body: some View {
        NavigationLink {
            StudentProgressDetailView(studentId: link.studentId, studentEmail: displayName)
        } label: {
            ArchivedStudentRow(link: link, displayName: displayName)
        }
    }
}

private struct ArchivedStudentRow: View {
    let link: StudentAdultLink
    let displayName: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(displayName.prefix(1).uppercased())
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(link.studentEmail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let archivedAt = link.archivedAt {
                Text(archivedAt.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
