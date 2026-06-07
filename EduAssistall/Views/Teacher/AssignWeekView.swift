import SwiftUI

struct AssignWeekView: View {
    let teacherProfile: UserProfile

    @State private var studentLinks: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var selectedStudentIds: Set<String> = []
    @State private var approvedDays: [Recommendation] = []
    @State private var weekOf = WeeklyAssignment.mondayOf(week: Date())
    @State private var isLoading = true
    @State private var isAssigning = false
    @State private var assignSuccess = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private var sortedDays: [Recommendation] {
        approvedDays.sorted { ($0.dayNumber ?? 0) < ($1.dayNumber ?? 0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Week starting", selection: $weekOf,
                               displayedComponents: [.date])
                        .onChange(of: weekOf) { _, new in
                            weekOf = WeeklyAssignment.mondayOf(week: new)
                        }
                } header: {
                    Text("Target Week")
                } footer: {
                    Text("Assignments will be scheduled Monday through Friday of the selected week.")
                }

                Section("Students") {
                    if studentLinks.isEmpty {
                        Text("No linked students found.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(studentLinks, id: \.studentId) { link in
                            let name = studentNames[link.studentId] ?? link.studentId
                            Toggle(name, isOn: Binding(
                                get: { selectedStudentIds.contains(link.studentId) },
                                set: { on in
                                    if on { selectedStudentIds.insert(link.studentId) }
                                    else  { selectedStudentIds.remove(link.studentId) }
                                }
                            ))
                        }
                    }
                }

                Section("Approved Lesson Days to Assign") {
                    if approvedDays.isEmpty {
                        Text("No approved lesson-day recommendations found.\nApprove lesson plans in AI Recommendations first.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sortedDays) { rec in
                            HStack(spacing: 12) {
                                Text("Day \(rec.dayNumber ?? 0)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .frame(width: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rec.title)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }

                if assignSuccess {
                    Section {
                        Label("Assignments created successfully!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    Button {
                        Task { await assign() }
                    } label: {
                        HStack {
                            Spacer()
                            if isAssigning { ProgressView() }
                            else { Text("Assign to Selected Students").fontWeight(.semibold) }
                            Spacer()
                        }
                    }
                    .disabled(
                        isAssigning ||
                        selectedStudentIds.isEmpty ||
                        approvedDays.isEmpty
                    )
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .background(Color.appGroupedBackground)
            .navigationTitle("Assign Week")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: adaptiveTopBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        let links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id))?.filter(\.confirmed) ?? []
        studentLinks = links
        for link in links {
            let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId))?.displayName ?? "Student"
            studentNames[link.studentId] = name
        }
        // Load all approved lessonDay recommendations created by this teacher
        let recs = (try? await FirestoreService.shared.fetchTeacherApprovedLessonDays(teacherId: teacherProfile.id)) ?? []
        approvedDays = recs
        isLoading = false
    }

    private func assign() async {
        isAssigning = true
        errorMessage = nil
        assignSuccess = false
        do {
            for studentId in selectedStudentIds {
                let studentName = studentNames[studentId] ?? "Student"
                _ = studentName // used for context; assignment stores teacher name
                for rec in sortedDays {
                    let a = WeeklyAssignment(
                        id: "\(teacherProfile.id)_\(studentId)_\(rec.id)",
                        studentId: studentId,
                        teacherId: teacherProfile.id,
                        teacherName: teacherProfile.displayName,
                        weekOf: weekOf,
                        dayNumber: rec.dayNumber ?? 1,
                        title: rec.title,
                        lessonPlanText: rec.lessonPlanText ?? rec.rationale,
                        archived: false,
                        assignedAt: Date(),
                        recommendationId: rec.id
                    )
                    try await FirestoreService.shared.saveWeeklyAssignment(a)
                }
            }
            assignSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isAssigning = false
    }
}
