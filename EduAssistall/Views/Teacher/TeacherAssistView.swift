import SwiftUI

struct TeacherAssistView: View {
    let teacherProfile: UserProfile

    @State private var summaries: [TeacherAssistStudentSummary] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var gradingResponse = ""
    @State private var gradingRubric = "4 = complete and accurate, 3 = mostly correct, 2 = partial understanding, 1 = needs reteach"
    @State private var selectedExitTicketSubject = "Math"
    @State private var selectedAccommodation = "Reading support"

    private var classCompletion: Int {
        guard !summaries.isEmpty else { return 0 }
        return Int(summaries.map(\.completionRate).reduce(0, +) / Double(summaries.count) * 100)
    }

    private var attentionList: [TeacherAssistStudentSummary] {
        summaries.filter(\.needsAttention).sorted { $0.riskScore > $1.riskScore }
    }

    private var standards: [StandardMastery] {
        let grouped = Dictionary(grouping: summaries.flatMap(\.standardResults), by: \.code)
        return grouped.map { code, values in
            let completion = values.map(\.completionRate).reduce(0, +) / Double(max(values.count, 1))
            return StandardMastery(code: code, subject: values.first?.subject ?? "General", completionRate: completion, students: values.map(\.studentName))
        }
        .sorted { $0.completionRate < $1.completionRate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let loadError {
                        Label(loadError, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 20)
                    }

                    overviewSection
                    analyticsSection
                    standardsHeatmapSection
                    smallGroupsSection
                    interventionSection
                    assignmentBuilderSection
                    gradingAssistantSection
                    exitTicketSection
                    parentUpdatesSection
                    accommodationsSection
                    engagementAlertsSection
                }
                .padding(.vertical, 16)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Teacher Assist")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var overviewSection: some View {
        AssistSection(title: "Class Snapshot", icon: "speedometer") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                AssistMetric(value: "\(summaries.count)", label: "Students", color: .blue)
                AssistMetric(value: "\(classCompletion)%", label: "Avg. Completion", color: .green)
                AssistMetric(value: "\(attentionList.count)", label: "Need Attention", color: attentionList.isEmpty ? .green : .orange)
                AssistMetric(value: "\(standards.filter { $0.completionRate < 0.7 }.count)", label: "Weak Standards", color: .purple)
            }
        }
    }

    private var analyticsSection: some View {
        AssistSection(title: "1. Performance Analytics", icon: "chart.line.uptrend.xyaxis") {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if attentionList.isEmpty {
                AssistEmptyLine("No urgent academic or engagement patterns found.")
            } else {
                ForEach(attentionList.prefix(6)) { student in
                    AssistStudentInsightRow(student: student)
                }
            }
        }
    }

    private var standardsHeatmapSection: some View {
        AssistSection(title: "2. Standards Mastery Heatmap", icon: "square.grid.3x3.fill") {
            if standards.isEmpty {
                AssistEmptyLine("No standards data yet. Add aligned standards to content items to enable this heatmap.")
            } else {
                ForEach(standards.prefix(8)) { standard in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(standard.code).font(.subheadline.bold())
                            Spacer()
                            Text("\(Int(standard.completionRate * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(standard.color)
                        }
                        ProgressView(value: standard.completionRate)
                            .tint(standard.color)
                        Text("\(standard.subject) · \(standard.students.prefix(3).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var smallGroupsSection: some View {
        AssistSection(title: "3. Small Group Generator", icon: "person.3.sequence.fill") {
            let groups = makeGroups()
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 5) {
                    Label(group.title, systemImage: group.icon)
                        .font(.subheadline.bold())
                        .foregroundStyle(group.color)
                    Text(group.students.isEmpty ? "No students currently match this group." : group.students.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(group.suggestion)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var interventionSection: some View {
        AssistSection(title: "4. Intervention Recommendations", icon: "cross.case.fill") {
            ForEach(attentionList.prefix(5)) { student in
                VStack(alignment: .leading, spacing: 5) {
                    Text(student.name).font(.subheadline.bold())
                    ForEach(student.interventions, id: \.self) { item in
                        Label(item, systemImage: "arrow.right.circle")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
            if attentionList.isEmpty { AssistEmptyLine("No interventions recommended from current data.") }
        }
    }

    private var assignmentBuilderSection: some View {
        AssistSection(title: "5. Assignment Builder", icon: "list.bullet.clipboard.fill") {
            let weakest = standards.first
            Text("Suggested differentiated set")
                .font(.subheadline.bold())
            VStack(alignment: .leading, spacing: 6) {
                Label("Reteach: 10-minute mini lesson on \(weakest?.code ?? "the current skill")", systemImage: "1.circle")
                Label("Practice: 5 scaffolded problems with worked examples", systemImage: "2.circle")
                Label("Apply: 2 word problems or a short constructed response", systemImage: "3.circle")
                Label("Extend: challenge prompt for students already above 85%", systemImage: "4.circle")
            }
            .font(.caption)
        }
    }

    private var gradingAssistantSection: some View {
        AssistSection(title: "6. Grading Assistant", icon: "checkmark.seal.fill") {
            Text("Paste a short response. EduAssist suggests feedback; the teacher keeps the final grade.")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Rubric", text: $gradingRubric, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $gradingResponse)
                .frame(minHeight: 90)
                .padding(6)
                .background(Color.appSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            let suggestion = gradingSuggestion
            if !suggestion.isEmpty {
                AssistCallout(title: "Suggested Feedback", text: suggestion, color: .blue)
            }
        }
    }

    private var exitTicketSection: some View {
        AssistSection(title: "7. Exit Ticket Analyzer", icon: "rectangle.and.pencil.and.ellipsis") {
            Picker("Subject", selection: $selectedExitTicketSubject) {
                ForEach(["Math", "ELA", "Science", "Social Studies"], id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
            VStack(alignment: .leading, spacing: 6) {
                Label("Question 1: Explain the key idea from today's lesson in one sentence.", systemImage: "1.circle")
                Label("Question 2: Solve one quick application problem for \(selectedExitTicketSubject).", systemImage: "2.circle")
                Label("Question 3: Mark confidence: ready, unsure, or need help.", systemImage: "3.circle")
            }
            .font(.caption)
            AssistCallout(title: "Analyzer", text: "Sort responses by misconception, confidence, and missing steps. Use the groups above for tomorrow's warm-up.", color: .teal)
        }
    }

    private var parentUpdatesSection: some View {
        AssistSection(title: "8. Parent Update Generator", icon: "envelope.badge.fill") {
            ForEach(summaries.prefix(4)) { student in
                VStack(alignment: .leading, spacing: 6) {
                    Text(student.name).font(.subheadline.bold())
                    Text(parentUpdate(for: student))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        copyToClipboard(parentUpdate(for: student))
                    } label: {
                        Label("Copy Draft", systemImage: "doc.on.doc")
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var accommodationsSection: some View {
        AssistSection(title: "9. IEP / 504 Accommodation Helper", icon: "accessibility.fill") {
            Picker("Support", selection: $selectedAccommodation) {
                ForEach(["Reading support", "Reduced writing load", "Extended time", "Chunked directions"], id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            AssistCallout(title: selectedAccommodation, text: accommodationText, color: .purple)
        }
    }

    private var engagementAlertsSection: some View {
        AssistSection(title: "10. Engagement Pattern Alerts", icon: "bell.badge.fill") {
            let alerts = summaries.flatMap(\.engagementAlerts)
            if alerts.isEmpty {
                AssistEmptyLine("No engagement alerts from current progress, session, or flag data.")
            } else {
                ForEach(alerts.prefix(8), id: \.self) { alert in
                    Label(alert, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var gradingSuggestion: String {
        let words = gradingResponse.split { $0.isWhitespace || $0.isNewline }.count
        guard words > 0 else { return "" }
        if words < 25 {
            return "Likely score: 2. The response is brief. Ask for one more evidence sentence and a clearer explanation of the reasoning."
        }
        if gradingResponse.localizedCaseInsensitiveContains("because") || gradingResponse.localizedCaseInsensitiveContains("therefore") {
            return "Likely score: 3-4. The response includes reasoning language. Check accuracy against the rubric, then approve or revise the feedback."
        }
        return "Likely score: 3. The response has enough length but may need clearer reasoning. Suggest adding 'because' plus one specific example."
    }

    private var accommodationText: String {
        switch selectedAccommodation {
        case "Reduced writing load":
            return "Keep the same standard, reduce copied text, allow bullet responses, and grade the target skill rather than handwriting volume."
        case "Extended time":
            return "Split the task into checkpoints and allow completion across two work blocks without reducing rigor."
        case "Chunked directions":
            return "Convert directions into 3 numbered steps with one example before independent work."
        default:
            return "Provide read-aloud support, vocabulary preview, and a sentence frame while keeping the same learning target."
        }
    }

    private func load() async {
        isLoading = true
        loadError = nil
        do {
            let links = try await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id).filter { $0.confirmed }
            let studentIds = links.map(\.studentId)
            async let sessionsFetch = FirestoreService.shared.fetchActiveSessions(studentIds: studentIds)
            let sessions = (try? await sessionsFetch) ?? [:]

            var loaded: [TeacherAssistStudentSummary] = []
            await withTaskGroup(of: TeacherAssistStudentSummary?.self) { group in
                for link in links {
                    group.addTask { await makeSummary(for: link, session: sessions[link.studentId]) }
                }
                for await item in group {
                    if let item { loaded.append(item) }
                }
            }
            summaries = loaded.sorted { $0.name < $1.name }
        } catch {
            loadError = "Couldn't load teacher assist data: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func makeSummary(for link: StudentAdultLink, session: ActiveSession?) async -> TeacherAssistStudentSummary? {
        async let profileFetch = FirestoreService.shared.fetchUserProfile(uid: link.studentId)
        async let pathsFetch = FirestoreService.shared.fetchAllLearningPaths(studentId: link.studentId)
        async let progressFetch = FirestoreService.shared.fetchAllProgress(studentId: link.studentId)
        async let attemptsFetch = FirestoreService.shared.fetchTestAttempts(studentId: link.studentId)
        async let flagsFetch = FirestoreService.shared.fetchRecentSessionFlags(studentId: link.studentId)

        let profile = try? await profileFetch
        let paths = (try? await pathsFetch) ?? []
        let progress = (try? await progressFetch) ?? []
        let attempts = (try? await attemptsFetch) ?? []
        let flags = (try? await flagsFetch) ?? []

        let contentIds = Array(Set(paths.flatMap { $0.items.map(\.contentItemId) }))
        let contentItems = (try? await FirestoreService.shared.fetchContentItems(ids: contentIds)) ?? []
        let progressById = Dictionary(uniqueKeysWithValues: progress.map { ($0.contentItemId, $0) })
        let totalItems = contentIds.count
        let completedItems = contentIds.filter { progressById[$0]?.status == .completed }.count
        let inProgressItems = contentIds.filter { progressById[$0]?.status == .inProgress }.count
        let minutes = progress.map(\.timeSpentMinutes).reduce(0, +)
        let lastActivity = progress.map(\.updatedAt).max() ?? session?.lastMessageAt
        let standards = contentItems.flatMap { item in
            item.alignedStandards.map { code in
                StandardResult(
                    code: code,
                    subject: item.subject,
                    studentName: profile?.displayName ?? link.studentEmail,
                    completionRate: progressById[item.id]?.status == .completed ? 1 : 0
                )
            }
        }

        return TeacherAssistStudentSummary(
            id: link.studentId,
            name: profile?.displayName ?? link.studentEmail,
            email: link.studentEmail,
            totalItems: totalItems,
            completedItems: completedItems,
            inProgressItems: inProgressItems,
            minutes: minutes,
            lastActivity: lastActivity,
            testAverage: attempts.isEmpty ? nil : Double(attempts.map(\.score).reduce(0, +)) / Double(attempts.count),
            recentFlags: flags.filter { !$0.acknowledged },
            activeSession: session,
            standardResults: standards
        )
    }

    private func makeGroups() -> [AssistGroup] {
        [
            AssistGroup(title: "Reteach", icon: "arrow.counterclockwise", color: .orange, students: summaries.filter { $0.completionRate < 0.5 }, suggestion: "Use teacher-led modeling and one scaffolded example."),
            AssistGroup(title: "Practice", icon: "pencil.line", color: .blue, students: summaries.filter { $0.completionRate >= 0.5 && $0.completionRate < 0.85 }, suggestion: "Assign targeted practice on the weakest standard."),
            AssistGroup(title: "Enrichment", icon: "sparkles", color: .green, students: summaries.filter { $0.completionRate >= 0.85 }, suggestion: "Offer a challenge task, peer explanation, or project extension.")
        ]
    }

    private func parentUpdate(for student: TeacherAssistStudentSummary) -> String {
        "\(student.name) has completed \(student.completedItems) of \(student.totalItems) assigned learning items. Current completion is \(Int(student.completionRate * 100))%. Next focus: \(student.primaryNeed)."
    }
}

private struct TeacherAssistStudentSummary: Identifiable {
    let id: String
    let name: String
    let email: String
    let totalItems: Int
    let completedItems: Int
    let inProgressItems: Int
    let minutes: Int
    let lastActivity: Date?
    let testAverage: Double?
    let recentFlags: [SessionFlag]
    let activeSession: ActiveSession?
    let standardResults: [StandardResult]

    var completionRate: Double {
        totalItems == 0 ? 0 : Double(completedItems) / Double(totalItems)
    }

    var riskScore: Int {
        var score = 0
        if completionRate < 0.5 { score += 3 }
        if let testAverage, testAverage < 70 { score += 2 }
        if isStale { score += 2 }
        if !recentFlags.isEmpty { score += 2 }
        if activeSession?.isActive == true, let last = activeSession?.lastMessageAt, Date().timeIntervalSince(last) > 600 { score += 1 }
        return score
    }

    var needsAttention: Bool { riskScore > 0 }
    var isStale: Bool {
        guard let lastActivity else { return totalItems > 0 }
        return Date().timeIntervalSince(lastActivity) > 7 * 24 * 60 * 60
    }
    var primaryNeed: String {
        if !recentFlags.isEmpty { return "review recent companion alerts" }
        if let testAverage, testAverage < 70 { return "reteach before the next assessment" }
        if completionRate < 0.5 { return "complete missing learning path items" }
        if isStale { return "restart engagement this week" }
        return "continue current learning path"
    }
    var interventions: [String] {
        var items: [String] = []
        if completionRate < 0.5 { items.append("Assign a 10-minute reteach and one short practice set.") }
        if let testAverage, testAverage < 70 { items.append("Review missed standards before another full assessment.") }
        if isStale { items.append("Send a check-in and set a small completion goal.") }
        if recentFlags.contains(where: { $0.type == .frustration }) { items.append("Offer a teacher hint or switch to step-by-step mode.") }
        if recentFlags.contains(where: { $0.type == .safety }) { items.append("Review the safety flag before assigning new AI work.") }
        return items.isEmpty ? ["Keep current plan and monitor progress."] : items
    }
    var engagementAlerts: [String] {
        var alerts: [String] = []
        if isStale { alerts.append("\(name): no recent progress update in 7+ days.") }
        if activeSession?.isActive == true, let last = activeSession?.lastMessageAt, Date().timeIntervalSince(last) > 600 {
            alerts.append("\(name): active session has gone quiet for 10+ minutes.")
        }
        if inProgressItems > completedItems && completionRate < 0.5 {
            alerts.append("\(name): starts work but is not completing at the same pace.")
        }
        alerts.append(contentsOf: recentFlags.prefix(2).map { "\(name): \($0.type.displayName) - \($0.reason)" })
        return alerts
    }
}

private struct StandardResult {
    let code: String
    let subject: String
    let studentName: String
    let completionRate: Double
}

private struct StandardMastery: Identifiable {
    var id: String { code }
    let code: String
    let subject: String
    let completionRate: Double
    let students: [String]
    var color: Color {
        completionRate < 0.5 ? .red : completionRate < 0.75 ? .orange : .green
    }
}

private struct AssistGroup: Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let color: Color
    let students: [TeacherAssistStudentSummary]
    let suggestion: String
}

private struct AssistSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 20)
    }
}

private struct AssistMetric: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AssistStudentInsightRow: View {
    let student: TeacherAssistStudentSummary

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: student.riskScore >= 5 ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(student.riskScore >= 5 ? .red : .orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(student.name)
                    .font(.subheadline.bold())
                Text("\(Int(student.completionRate * 100))% complete · \(student.primaryNeed)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

private struct AssistCallout: View {
    let title: String
    let text: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.bold()).foregroundStyle(color)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AssistEmptyLine: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
