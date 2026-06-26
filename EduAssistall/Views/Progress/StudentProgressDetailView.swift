import SwiftUI

// Used by parents and teachers to view a specific student's progress.
// Pass teacherId when used in a teacher context to unlock grading and companion config.
struct StudentProgressDetailView: View {
    let studentId: String
    let studentEmail: String
    var teacherId: String? = nil

    @State private var paths: [LearningPath] = []
    @State private var progressMap: [String: StudentProgress] = [:]
    @State private var studentFiles: [SharedFile] = []
    @State private var thisWeekAssignments: [WeeklyAssignment] = []
    @State private var grades: [String: StudentGrade] = [:]
    @State private var isLoading = true
    @State private var showCompanionSettings = false
    @State private var gradingAssignment: WeeklyAssignment?

    private var allItems: [LearningPathItem] { paths.flatMap(\.items) }
    private var completedCount: Int {
        allItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
    }
    private var totalCount: Int { allItems.count }
    private var overallFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    private var teacherAssignments: [WeeklyAssignment] {
        guard let tid = teacherId else { return [] }
        return thisWeekAssignments.filter { $0.teacherId == tid }
            .sorted { $0.dayNumber < $1.dayNumber }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        overallStatsCard

                        if paths.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.tertiary)
                                Text("No learning paths assigned yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 30)
                        } else {
                            learningPathsSection
                        }

                        if teacherId != nil && !teacherAssignments.isEmpty {
                            assignmentsSection
                        }

                        if !studentFiles.isEmpty {
                            submittedFilesSection
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(studentEmail)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    if teacherId != nil {
                        Button {
                            showCompanionSettings = true
                        } label: {
                            Image(systemName: "brain.head.profile")
                        }
                    }
                    NavigationLink {
                        ReportDetailView(studentId: studentId, studentName: studentEmail)
                    } label: {
                        Image(systemName: "chart.bar.doc.horizontal")
                    }
                }
            }
        }
        .sheet(isPresented: $showCompanionSettings) {
            StudentCompanionSettingsView(studentId: studentId, studentName: studentEmail)
        }
        .sheet(item: $gradingAssignment) { assignment in
            GradeAssignmentSheet(
                assignment: assignment,
                teacherId: teacherId ?? "",
                existingGrade: grades[assignment.id]
            ) { saved in
                grades[assignment.id] = saved
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Subviews

    private var overallStatsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                ProgressRing(fraction: overallFraction, size: 90)
                VStack(alignment: .leading, spacing: 10) {
                    StatRow(value: "\(completedCount)", label: "Lessons Completed", color: .green)
                    StatRow(value: "\(totalCount - completedCount)", label: "Remaining", color: .orange)
                    StatRow(value: "\(paths.count)", label: "Learning Paths", color: .blue)
                }
            }
        }
        .padding(20)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private var learningPathsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Paths")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(paths) { path in
                PathProgressCard(path: path, progressMap: progressMap)
                    .padding(.horizontal, 20)
            }
        }
    }

    private var assignmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This Week's Assignments")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(teacherAssignments) { assignment in
                TeacherAssignmentRow(
                    assignment: assignment,
                    grade: grades[assignment.id]
                )
                .padding(.horizontal, 20)
                .contentShape(Rectangle())
                .onTapGesture { gradingAssignment = assignment }
            }
        }
    }

    private var submittedFilesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Submitted Files")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(studentFiles) { file in
                SharedFileRow(file: file)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Data loading

    private func load() async {
        isLoading = true
        let monday = WeeklyAssignment.mondayOf(week: Date())

        async let fetchPaths = FirestoreService.shared.fetchAllLearningPaths(studentId: studentId)
        async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: studentId)
        async let fetchFiles = FirestoreService.shared.fetchIndividualFiles(studentId: studentId)
        async let fetchAssignments: [WeeklyAssignment] = {
            guard teacherId != nil else { return [] }
            return (try? await FirestoreService.shared.fetchWeeklyAssignments(
                studentId: studentId, weekOf: monday
            )) ?? []
        }()

        let loadedPaths   = (try? await fetchPaths) ?? []
        let progressList  = (try? await fetchProgress) ?? []
        studentFiles      = (try? await fetchFiles) ?? []
        thisWeekAssignments = await fetchAssignments

        paths        = loadedPaths.sorted { $0.createdAt > $1.createdAt }
        progressMap  = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })

        // Fetch grades for this teacher's assignments this week
        if let tid = teacherId {
            let gradeList = (try? await FirestoreService.shared.fetchStudentGrades(
                studentId: studentId, teacherId: tid
            )) ?? []
            grades = Dictionary(uniqueKeysWithValues: gradeList.map { ($0.assignmentId, $0) })
        }

        isLoading = false
    }
}

// MARK: - Teacher Assignment Row

private struct TeacherAssignmentRow: View {
    let assignment: WeeklyAssignment
    let grade: StudentGrade?

    private var dayColor: Color {
        switch assignment.dayNumber {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        default: return .red
        }
    }

    private var gradeColor: Color {
        guard let g = grade else { return .clear }
        switch g.score {
        case 90...:   return .green
        case 80..<90: return .blue
        case 70..<80: return .yellow
        case 60..<70: return .orange
        default:      return .red
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(assignment.dayLabel.prefix(3))
                    .font(.caption2.bold())
                    .foregroundStyle(dayColor)
                Text("\(Calendar.current.component(.day, from: assignment.scheduledDate))")
                    .font(.title3.bold())
                    .foregroundStyle(dayColor)
            }
            .frame(width: 44)

            Rectangle()
                .fill(dayColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 3) {
                Text(assignment.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
            }

            Spacer()

            if let g = grade {
                VStack(spacing: 1) {
                    Text(g.letterGrade)
                        .font(.headline.bold())
                        .foregroundStyle(gradeColor)
                    Text(String(format: "%.0f%%", g.score))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Grade", systemImage: "square.and.pencil")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(dayColor.opacity(0.2), lineWidth: 1)
        )
    }
}
