import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

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
    @State private var showLessonPlan = false
    @State private var showBehaviorDocumentation = false
    @State private var assignPathStudent: StudentAdultLink? = nil
    @State private var activePathCount = 0
    @State private var documentationRecords: [TeacherDocumentationRecord] = []

    private var confirmedStudents: [StudentAdultLink] {
        linkedStudents.filter(\.confirmed)
    }
    private var confirmedIds: [String] { confirmedStudents.map(\.studentId) }
    private var totalPending: Int { pendingByStudent.values.reduce(0, +) }
    private var openDocumentationTasks: [TeacherDocumentationRecord] {
        documentationRecords
            .filter { $0.followUpStatus == .needsFollowUp || $0.followUpStatus == .referredToAdmin }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

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
                    teacherTasks
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
                            Label("Invite Student", systemImage: "person.badge.plus")
                        }
                        Button { showImport = true } label: {
                            Label("Import Roster (CSV)", systemImage: "square.and.arrow.down")
                        }
                        Divider()
                        Button(role: .destructive) {
                            Task { @MainActor in authVM.signOut() }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .accessibilityIdentifier("sign_out_button")
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
                    .macSheetFrame(width: 820, height: 700)
            }
            .sheet(isPresented: $showImport, onDismiss: { Task { await loadStudents() } }) {
                BulkImportView(teacherProfile: profile)
                    .macSheetFrame(width: 820, height: 680)
            }
            .sheet(isPresented: $showAddStudent, onDismiss: { Task { await loadStudents() } }) {
                AddStudentView(teacherProfile: profile)
                    .macSheetFrame(width: 720, height: 620)
            }
            .sheet(isPresented: $showLessonPlan) {
                GenerateLessonPlanView(teacherProfile: profile)
                    .macSheetFrame(width: 1100, height: 780)
            }
            .sheet(isPresented: $showBehaviorDocumentation, onDismiss: { Task { await loadStudents() } }) {
                BehaviorDocumentationView(teacherProfile: profile)
                    .macSheetFrame(width: 880, height: 760)
            }
            .sheet(item: $assignPathStudent) { link in
                CreateLearningPathView(teacherProfile: profile, preselectedLink: link) {
                    Task { await loadStudents() }
                }
                .macSheetFrame(width: 940, height: 720)
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
                                  icon: "checkmark.seal.fill",
                                  color: totalPending > 0 ? .orange : .green,
                                  highlight: totalPending > 0)
            }
            .buttonStyle(.plain)
            DashboardStatCard(value: "\(activePathCount)",
                              label: "Active Paths",
                              icon: "list.clipboard.fill",
                              color: .purple)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Teacher Tasks

    private var teacherTasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Teacher Tasks")
                        .font(.headline)
                    Text(openDocumentationTasks.isEmpty ? "No open behavior follow-ups." : "\(openDocumentationTasks.count) documentation follow-up\(openDocumentationTasks.count == 1 ? "" : "s") need attention.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showBehaviorDocumentation = true
                } label: {
                    Label("Document", systemImage: "square.and.pencil")
                        .font(.caption.bold())
                }
            }

            if openDocumentationTasks.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("You are clear on documented behavior follow-ups.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(openDocumentationTasks.prefix(3)) { record in
                    TeacherTaskCard(record: record) {
                        copyToClipboard(record.adminReadySummary)
                    } onCopyParentDraft: {
                        copyToClipboard(ParentContactDraftBuilder.draft(for: record, teacherName: profile.displayName))
                    } onResolve: {
                        await markDocumentationTaskResolved(record)
                    }
                }
            }
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
                                                  studentEmail: link.studentEmail,
                                                  teacherId: profile.id)
                    } label: {
                        TeacherStudentRow(
                            link: link,
                            displayName: studentNames[link.studentId] ?? link.studentEmail,
                            pendingCount: pendingByStudent[link.studentId] ?? 0
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .contextMenu {
                        Button {
                            assignPathStudent = link
                        } label: {
                            Label("Assign Learning Path", systemImage: "paperplane.fill")
                        }
                    }
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
                Button {
                    showLessonPlan = true
                } label: {
                    QuickActionCard(icon: "calendar.badge.checkmark", label: "Plan Lesson", color: .blue)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeacherLearningPathView(teacherProfile: profile)
                } label: {
                    QuickActionCard(icon: "paperplane.fill", label: "Assign Path", color: .purple)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeacherAssistView(teacherProfile: profile)
                } label: {
                    QuickActionCard(icon: "lightbulb.fill", label: "Teacher Assist", color: .mint)
                }
                .buttonStyle(.plain)

                Button {
                    showBehaviorDocumentation = true
                } label: {
                    QuickActionCard(icon: "doc.text.fill", label: "Document Behavior", color: .orange)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PendingRecommendationsView(reviewerProfile: profile, studentIds: confirmedIds)
                } label: {
                    QuickActionCard(icon: "checkmark.seal.fill", label: "Review AI Recs",
                                    color: .orange, badge: totalPending > 0 ? "\(totalPending)" : nil)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TeacherReportsDestination(confirmedStudents: confirmedStudents)
                } label: {
                    QuickActionCard(icon: "doc.text.magnifyingglass", label: "Reports", color: .teal)
                }
                .buttonStyle(.plain)
                .disabled(confirmedStudents.isEmpty)

                NavigationLink {
                    MessagesListView(profile: profile)
                } label: {
                    QuickActionCard(icon: "bubble.left.and.bubble.right.fill", label: "Messages", color: .cyan)
                }
                .buttonStyle(.plain)

                Button { showAddStudent = true } label: {
                    QuickActionCard(icon: "person.badge.plus", label: "Invite Student", color: .indigo)
                }
                .buttonStyle(.plain)

                Button { showManageRoster = true } label: {
                    QuickActionCard(icon: "list.bullet.rectangle", label: "Manage Roster", color: .gray)
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

            // Load names, pending recs, and active path count in parallel
            async let pendingFetch = FirestoreService.shared.fetchPendingRecommendations(studentIds: ids)
            async let pathsFetch = FirestoreService.shared.fetchLearningPathsCreatedBy(teacherId: profile.id)
            async let documentationFetch = FirestoreService.shared.fetchTeacherDocumentationRecords(teacherId: profile.id)

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

            let paths = (try? await pathsFetch) ?? []
            activePathCount = paths.filter(\.isActive).count

            documentationRecords = (try? await documentationFetch) ?? []
        } catch {
            loadError = error
        }
        isLoading = false
    }

    private func copyToClipboard(_ text: String) {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    private func markDocumentationTaskResolved(_ record: TeacherDocumentationRecord) async {
        do {
            try await FirestoreService.shared.updateTeacherDocumentationFollowUpStatus(
                teacherId: profile.id,
                recordId: record.id,
                status: .resolved
            )
            if let index = documentationRecords.firstIndex(where: { $0.id == record.id }) {
                documentationRecords[index].followUpStatus = .resolved
                documentationRecords[index].updatedAt = Date()
            }
        } catch {
            loadError = error
        }
    }
}

// MARK: - Teacher Task Card

private struct TeacherTaskCard: View {
    let record: TeacherDocumentationRecord
    let onCopySummary: () -> Void
    let onCopyParentDraft: () -> Void
    let onResolve: () async -> Void
    @State private var isResolving = false

    private var title: String {
        switch record.followUpStatus {
        case .needsFollowUp:
            return "Follow up with \(record.studentName)"
        case .referredToAdmin:
            return "Check admin referral"
        case .contactedHome:
            return "Home contacted"
        case .resolved:
            return "Resolved"
        case .none:
            return "Documentation note"
        }
    }

    private var subtitle: String {
        let nextStep = record.nextStep.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nextStep.isEmpty { return nextStep }
        return record.category == .distraction
            ? "Review the distraction pattern and choose the next classroom support."
            : "Review the record and choose the next support action."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text("\(record.category.displayName) · \(record.occurredAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(record.followUpStatus.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(record.followUpStatus == .referredToAdmin ? .orange : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((record.followUpStatus == .referredToAdmin ? Color.orange : Color.blue).opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Menu {
                    Button(action: onCopySummary) {
                        Label("Copy Summary", systemImage: "doc.on.doc")
                    }
                    Button(action: onCopyParentDraft) {
                        Label("Copy Parent Draft", systemImage: "envelope")
                    }
                    Button {
                        Task {
                            isResolving = true
                            await onResolve()
                            isResolving = false
                        }
                    } label: {
                        Label("Mark Resolved", systemImage: "checkmark.circle")
                    }
                    .disabled(isResolving)
                } label: {
                    Label(isResolving ? "Resolving..." : "Actions",
                          systemImage: isResolving ? "hourglass" : "ellipsis.circle")
                }
                .font(.caption)
                Spacer()
                Text(record.studentName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private enum ParentContactDraftBuilder {
    static func draft(for record: TeacherDocumentationRecord, teacherName: String) -> String {
        let student = record.studentName
        let summary = record.objectiveSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = record.teacherAction.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = record.studentResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextStep = record.nextStep.trimmingCharacters(in: .whitespacesAndNewlines)

        var lines: [String] = []
        lines.append("Hello,")
        lines.append("")
        lines.append("I wanted to share a quick update about \(student) from class on \(record.occurredAt.formatted(date: .abbreviated, time: .shortened)).")
        if !summary.isEmpty {
            lines.append("")
            lines.append("What I observed: \(summary)")
        }
        if !action.isEmpty {
            lines.append("")
            lines.append("Support provided in class: \(action)")
        }
        if !response.isEmpty {
            lines.append("")
            lines.append("Student response: \(response)")
        }
        if !nextStep.isEmpty {
            lines.append("")
            lines.append("Next step: \(nextStep)")
        } else {
            lines.append("")
            lines.append("Next step: I will continue monitoring and supporting \(student) in class.")
        }
        lines.append("")
        lines.append("Please let me know if there is anything helpful I should know from home. This message is meant to support \(student), not to assign a consequence.")
        lines.append("")
        lines.append("Thank you,")
        lines.append(teacherName)
        return lines.joined(separator: "\n")
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
    @State private var assignPathStudent: StudentAdultLink? = nil

    var body: some View {
        NavigationStack {
            List(students) { link in
                NavigationLink {
                    StudentProgressDetailView(studentId: link.studentId,
                                              studentEmail: link.studentEmail,
                                              teacherId: teacherProfile.id)
                } label: {
                    TeacherStudentRow(
                        link: link,
                        displayName: studentNames[link.studentId] ?? link.studentEmail,
                        pendingCount: pendingByStudent[link.studentId] ?? 0
                    )
                    .padding(.vertical, 4)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        assignPathStudent = link
                    } label: {
                        Label("Assign Path", systemImage: "paperplane.fill")
                    }
                    .tint(.purple)
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
        .sheet(item: $assignPathStudent) { link in
            CreateLearningPathView(teacherProfile: teacherProfile, preselectedLink: link) {
                assignPathStudent = nil
            }
            .macSheetFrame(width: 940, height: 720)
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
