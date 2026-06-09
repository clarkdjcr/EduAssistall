import SwiftUI

/// Admin view into a single teacher's roster.
/// Provides school-admin-level actions: trigger year-end rollover or transfer
/// the entire class to another teacher on behalf of the teacher.
struct TeacherAdminDetailView: View {
    let teacher: UserProfile

    @State private var links: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var isLoading = true
    @State private var showRollover = false
    @State private var showTransfer = false

    private var confirmed: [StudentAdultLink] { links.filter { $0.confirmed && !$0.archived } }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Teacher info header
                    Section {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(teacher.displayName.prefix(1).uppercased())
                                        .font(.title3.bold())
                                        .foregroundStyle(.blue)
                                )
                            VStack(alignment: .leading, spacing: 3) {
                                Text(teacher.displayName)
                                    .font(.headline)
                                Text(teacher.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Admin actions
                    Section("Admin Actions") {
                        Button {
                            showRollover = true
                        } label: {
                            Label("End School Year for This Teacher…", systemImage: "calendar.badge.checkmark")
                        }
                        .disabled(confirmed.isEmpty)

                        Button {
                            showTransfer = true
                        } label: {
                            Label("Transfer Entire Class…", systemImage: "arrow.triangle.2.circlepath.circle")
                        }
                        .disabled(confirmed.isEmpty)
                    }

                    // Active roster
                    if !confirmed.isEmpty {
                        Section("Active Roster (\(confirmed.count))") {
                            ForEach(confirmed) { link in
                                NavigationLink {
                                    StudentProgressDetailView(
                                        studentId: link.studentId,
                                        studentName: studentNames[link.studentId] ?? link.studentEmail
                                    )
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.secondary.opacity(0.12))
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Text((studentNames[link.studentId] ?? link.studentEmail).prefix(1).uppercased())
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.secondary)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(studentNames[link.studentId] ?? link.studentEmail)
                                                .font(.subheadline)
                                                .lineLimit(1)
                                            Text(link.studentEmail)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }

                    if confirmed.isEmpty {
                        Section {
                            Text("No active students on this teacher's roster.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
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
        .navigationTitle(teacher.displayName)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { Task { await load() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: $showRollover) {
            EndSchoolYearSheet(teacherProfile: teacher, activeLinks: confirmed) {
                links.removeAll { $0.confirmed && !$0.archived }
            }
            .macSheetFrame(width: 560, height: 420)
        }
        .sheet(isPresented: $showTransfer) {
            TransferClassView(teacherProfile: teacher, activeLinks: confirmed) {
                links.removeAll { $0.confirmed && !$0.archived }
            }
            .macSheetFrame(width: 620, height: 520)
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacher.id)) ?? []
        await withTaskGroup(of: Void.self) { group in
            for link in links where link.confirmed {
                group.addTask {
                    let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId))?.displayName
                    await MainActor.run { if let name { studentNames[link.studentId] = name } }
                }
            }
        }
        isLoading = false
    }
}
