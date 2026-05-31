import SwiftUI

struct TeacherDashboardView: View {
    let profile: UserProfile

    @Environment(AuthViewModel.self) private var authVM
    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var pendingByStudent: [String: Int] = [:]
    @State private var isLoading = true
    @State private var loadError: Error?
    @State private var showAllStudents = false
    @State private var showImport = false
    @State private var showManageRoster = false
    @State private var showAddStudent = false

    private var confirmedStudents: [StudentAdultLink] {
        linkedStudents.filter(\.confirmed)
    }
    private var confirmedIds: [String] { confirmedStudents.map(\.studentId) }
    private var totalPending: Int { pendingByStudent.values.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greetingHeader
                    if let loadError {
                        Label("Couldn't load data — \(loadError.localizedDescription)",
                              systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 20)
                    }
                    statsRow
                    studentRoster
                    quickActions
                    Spacer(minLength: 32)
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Teacher Dashboard")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showAddStudent = true } label: {
                            Label("Add Student", systemImage: "person.badge.plus")
                        }
                        Button { showImport = true } label: {
                            Label("Import Roster (CSV)", systemImage: "arrow.down.doc")
                        }
                        Divider()
                        Button(role: .destructive) {
                            Task { @MainActor in authVM.signOut() }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task { await loadStudents() }
            .refreshable { await loadStudents() }
            .sheet(isPresented: $showAllStudents) {
                AllStudentsSheet(students: confirmedStudents,
                                 studentNames: studentNames,
                                 pendingByStudent: pendingByStudent,
                                 teacherProfile: profile)
            }
            .sheet(isPresented: $showImport, onDismiss: { Task { await loadStudents() } }) {
                BulkImportView(teacherProfile: profile)
            }
            .sheet(isPresented: $showAddStudent, onDismiss: { Task { await loadStudents() } }) {
                AddStudentView(teacherProfile: profile)
            }
            .navigationDestination(isPresented: $showManageRoster) {
                RosterManagementView(teacherProfile: profile)
            }
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back,")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(profile.displayName)
                .font(.largeTitle.bold())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            DashboardStatCard(value: "\(confirmedStudents.count)",
                              label: "Students",
                              icon: "person.3.fill",
                              color: .blue)
            NavigationLink {
                PendingRecommendationsView(reviewerProfile: profile, studentIds: confirmedIds)
            } label: {
                DashboardStatCard(value: "\(totalPending)",
                                  label: "Pending Reviews",
                                  icon: "checkmark.shield.fill",
                                  color: totalPending > 0 ? .orange : .green,
                                  highlight: totalPending > 0)
            }
            .buttonStyle(.plain)
            DashboardStatCard(value: "\(confirmedStudents.count)",
                              label: "Active Paths",
                              icon: "book.fill",
                              color: .purple)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Student Roster

    private var studentRoster: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Students")
                    .font(.headline)
                Spacer()
                if confirmedStudents.count > 3 {
                    Button("See All (\(confirmedStudents.count))") {
                        showAllStudents = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 20)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if confirmedStudents.isEmpty {
                TeacherEmptyState(
                    icon: "person.badge.plus",
                    message: "No students linked yet.\nStudents can join using your class code."
                )
                .padding(.horizontal, 20)
            } else {
                ForEach(confirmedStudents.prefix(3)) { link in
                    NavigationLink {
                        StudentProgressDetailView(studentId: link.studentId,
                                                  studentEmail: link.studentEmail)
                    } label: {
                        TeacherStudentRow(
                            link: link,
                            displayName: studentNames[link.studentId] ?? link.studentEmail,
                            pendingCount: pendingByStudent[link.studentId] ?? 0
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                NavigationLink {
                    TeacherLearningPathView(teacherProfile: profile)
                } label: {
                    QuickActionCard(icon: "book.fill", label: "Learning Paths", color: .purple)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PendingRecommendationsView(reviewerProfile: profile, studentIds: confirmedIds)
                } label: {
                    QuickActionCard(icon: "checkmark.shield.fill", label: "Review AI Recs",
                                    color: .orange, badge: totalPending > 0 ? "\(totalPending)" : nil)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    MessagesListView(profile: profile)
                } label: {
                    QuickActionCard(icon: "message.fill", label: "Messages", color: .blue)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeacherAssistView(teacherProfile: profile)
                } label: {
                    QuickActionCard(icon: "wand.and.stars", label: "Teacher Assist", color: .mint)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeacherReportsDestination(confirmedStudents: confirmedStudents)
                } label: {
                    QuickActionCard(icon: "chart.bar.fill", label: "Reports", color: .teal)
                }
                .buttonStyle(.plain)
                .disabled(confirmedStudents.isEmpty)

                Button { showAddStudent = true } label: {
                    QuickActionCard(icon: "person.badge.plus", label: "Add Student", color: .indigo)
                }
                .buttonStyle(.plain)

                Button { showManageRoster = true } label: {
                    QuickActionCard(icon: "person.fill.badge.minus", label: "Manage Roster", color: .gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Load

    private func loadStudents() async {
        isLoading = true
        loadError = nil
        do {
            linkedStudents = try await FirestoreService.shared.fetchLinkedStudents(adultId: profile.id)
            let confirmed = linkedStudents.filter(\.confirmed)
            let ids = confirmed.map(\.studentId)

            // Load names and pending recs in parallel
            async let pendingFetch = FirestoreService.shared.fetchPendingRecommendations(studentIds: ids)
            var names: [String: String] = [:]
            await withTaskGroup(of: (String, String?).self) { group in
                for link in confirmed {
                    group.addTask {
                        let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId))?.displayName
                        return (link.studentId, name)
                    }
                }
                for await (sid, name) in group {
                    if let name { names[sid] = name }
                }
            }
            studentNames = names

            let pending = (try? await pendingFetch) ?? []
            var map: [String: Int] = [:]
            for rec in pending { map[rec.studentId, default: 0] += 1 }
            pendingByStudent = map
        } catch {
            loadError = error
        }
        isLoading = false
    }
}

// MARK: - Reports Destination

private struct TeacherReportsDestination: View {
    let confirmedStudents: [StudentAdultLink]
    var body: some View {
        if confirmedStudents.count == 1, let s = confirmedStudents.first {
            ReportDetailView(studentId: s.studentId, studentName: s.studentEmail)
        } else {
            List(confirmedStudents) { link in
                NavigationLink(link.studentEmail) {
                    ReportDetailView(studentId: link.studentId, studentName: link.studentEmail)
                }
            }
            .navigationTitle("Reports")
        }
    }
}

// MARK: - All Students Sheet

private struct AllStudentsSheet: View {
    let students: [StudentAdultLink]
    let studentNames: [String: String]
    let pendingByStudent: [String: Int]
    let teacherProfile: UserProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(students) { link in
                NavigationLink {
                    StudentProgressDetailView(studentId: link.studentId,
                                              studentEmail: link.studentEmail)
                } label: {
                    TeacherStudentRow(
                        link: link,
                        displayName: studentNames[link.studentId] ?? link.studentEmail,
                        pendingCount: pendingByStudent[link.studentId] ?? 0
                    )
                    .padding(.vertical, 4)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .navigationTitle("All Students")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Student Row

private struct TeacherStudentRow: View {
    let link: StudentAdultLink
    let displayName: String
    let pendingCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 42, height: 42)
                .overlay(
                    Text(String(displayName.prefix(1)).uppercased())
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
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
            if pendingCount > 0 {
                Text("\(pendingCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let icon: String
    let label: String
    let color: Color
    var badge: String? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(label)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if let badge {
                Text(badge)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .offset(x: -8, y: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(badge.map { "\($0) pending" } ?? "")
    }
}

// MARK: - Empty State

private struct TeacherEmptyState: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
