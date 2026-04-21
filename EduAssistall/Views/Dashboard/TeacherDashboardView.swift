import SwiftUI

struct TeacherDashboardView: View {
    let profile: UserProfile

    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var pendingByStudent: [String: Int] = [:]
    @State private var isLoading = true
    @State private var showAllStudents = false
    @State private var showImport = false
    @State private var showManageRoster = false

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
                    statsRow
                    studentRoster
                    quickActions
                    Spacer(minLength: 32)
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Teacher Dashboard")
            .inlineNavigationTitle()
            .task { await loadStudents() }
            .refreshable { await loadStudents() }
            .sheet(isPresented: $showAllStudents) {
                AllStudentsSheet(students: confirmedStudents,
                                 pendingByStudent: pendingByStudent,
                                 teacherProfile: profile)
            }
            .sheet(isPresented: $showImport, onDismiss: { Task { await loadStudents() } }) {
                BulkImportView(teacherProfile: profile)
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
            TeacherStatCard(value: "\(confirmedStudents.count)",
                            label: "Students",
                            icon: "person.3.fill",
                            color: .blue)
            NavigationLink {
                PendingRecommendationsView(reviewerProfile: profile, studentIds: confirmedIds)
            } label: {
                TeacherStatCard(value: "\(totalPending)",
                                label: "Pending Reviews",
                                icon: "checkmark.shield.fill",
                                color: totalPending > 0 ? .orange : .green,
                                highlight: totalPending > 0)
            }
            .buttonStyle(.plain)
            TeacherStatCard(value: "\(confirmedStudents.count)",
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
                        TeacherStudentRow(link: link, pendingCount: pendingByStudent[link.studentId] ?? 0)
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
                    ReportDetailView(studentId: confirmedStudents.first?.studentId ?? "",
                                     studentName: confirmedStudents.first?.studentEmail ?? "Student")
                } label: {
                    QuickActionCard(icon: "chart.bar.fill", label: "Reports", color: .teal)
                }
                .buttonStyle(.plain)
                .disabled(confirmedStudents.isEmpty)

                Button { showImport = true } label: {
                    QuickActionCard(icon: "arrow.down.doc.fill", label: "Import Roster", color: .indigo)
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
        linkedStudents = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: profile.id)) ?? []
        let ids = confirmedStudents.map(\.studentId)
        let pending = (try? await FirestoreService.shared.fetchPendingRecommendations(studentIds: ids)) ?? []
        // Group pending counts by studentId
        var map: [String: Int] = [:]
        for rec in pending { map[rec.studentId, default: 0] += 1 }
        pendingByStudent = map
        isLoading = false
    }
}

// MARK: - All Students Sheet

private struct AllStudentsSheet: View {
    let students: [StudentAdultLink]
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
                    TeacherStudentRow(link: link, pendingCount: pendingByStudent[link.studentId] ?? 0)
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
    let pendingCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 42, height: 42)
                .overlay(
                    Text(String(link.studentEmail.prefix(1)).uppercased())
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(link.studentEmail)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(link.confirmed ? "Active" : "Pending confirmation")
                    .font(.caption)
                    .foregroundStyle(link.confirmed ? .green : .orange)
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

// MARK: - Stat Card

private struct TeacherStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var highlight = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(highlight ? color : .primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(highlight ? color.opacity(0.08) : Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(highlight ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
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
