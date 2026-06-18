import SwiftUI

// MARK: - Browse List

struct DailyLessonPlansView: View {
    let teacherProfile: UserProfile

    private static let allGrades = ["All","K","1","2","3","4","5","6","7","8","9-10","11-12"]

    @State private var plans:         [DailyLessonPlan] = []
    @State private var isLoading      = true
    @State private var errorMessage:  String?
    @State private var gradeFilter    = "All"
    @State private var statusFilter   = "All"
    @State private var searchText     = ""

    private var filtered: [DailyLessonPlan] {
        plans.filter { plan in
            let matchesGrade  = gradeFilter == "All" || plan.gradeLevel == gradeFilter
            let matchesStatus = statusFilter == "All" || plan.status.rawValue == statusFilter
            let matchesSearch = searchText.isEmpty ||
                plan.standardCode.localizedCaseInsensitiveContains(searchText) ||
                plan.standardDescription.localizedCaseInsensitiveContains(searchText) ||
                plan.grade.localizedCaseInsensitiveContains(searchText)
            return matchesGrade && matchesStatus && matchesSearch
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading lesson plans…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                errorView(err)
            } else {
                planList
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Daily Lesson Plans")
        .inlineNavigationTitle()
        .searchable(text: $searchText, prompt: "Search by standard or description")
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Plan List

    private var planList: some View {
        List {
            filterBar
                .listRowBackground(Color.appGroupedBackground)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))

            if filtered.isEmpty {
                emptyState
                    .listRowBackground(Color.appGroupedBackground)
            } else {
                ForEach(filtered) { plan in
                    NavigationLink {
                        DailyLessonPlanDetailView(plan: plan, teacherProfile: teacherProfile) {
                            Task { await load() }
                        }
                    } label: {
                        PlanRow(plan: plan)
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

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", binding: $gradeFilter, value: "All", color: .blue)
                ForEach(Self.allGrades.dropFirst(), id: \.self) { g in
                    filterChip(g == "K" ? "K" : "Gr \(g)", binding: $gradeFilter, value: g, color: .green)
                }
                Divider().frame(height: 20)
                filterChip("Draft",    binding: $statusFilter, value: "All",      color: .secondary)
                filterChip("Draft",    binding: $statusFilter, value: "draft",    color: .orange)
                filterChip("Approved", binding: $statusFilter, value: "approved", color: .blue)
                filterChip("Assigned", binding: $statusFilter, value: "assigned", color: .green)
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(_ label: String, binding: Binding<String>, value: String, color: Color) -> some View {
        let isSelected = binding.wrappedValue == value
        return Button {
            binding.wrappedValue = value
        } label: {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? color.opacity(0.15) : Color.appSecondaryBackground)
                .foregroundStyle(isSelected ? color : .secondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No Plans Match")
                .font(.title3.bold())
            Text("Try clearing the grade or status filter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(msg)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Retry") { Task { await load() } }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            plans = try await FirestoreService.shared.fetchDailyLessonPlans()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Plan Row

private struct PlanRow: View {
    let plan: DailyLessonPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Day \(plan.dayNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
                Spacer()
                StatusBadge(status: plan.status)
            }
            Text(plan.standardCode)
                .font(.subheadline.bold())
            Text(plan.standardDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 6) {
                chip(plan.grade, color: .green)
                chip(plan.subject, color: .orange)
                if !plan.strand.isEmpty {
                    chip(strandAbbrev(plan.strand), color: .purple)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func chip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func strandAbbrev(_ strand: String) -> String {
        if strand.contains("Complex") { return "Complex Texts" }
        if strand.contains("Communication") { return "Comm & Writing" }
        if strand.contains("Foundational") { return "Foundational" }
        return strand
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: DailyLessonPlanStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.12))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch status {
        case .draft:    return .orange
        case .approved: return .blue
        case .assigned: return .green
        }
    }
}

// MARK: - Detail / Review / Assign

struct DailyLessonPlanDetailView: View {
    let plan: DailyLessonPlan
    let teacherProfile: UserProfile
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    // Editable suggestion fields (seeded from plan's resolved values)
    @State private var primaryText:     String
    @State private var alternativeText: String
    @State private var activities:      [String]
    @State private var studentPrompt:   String
    @State private var teacherNotes:    String

    // Assignment state
    @State private var linkedStudents:   [StudentAdultLink] = []
    @State private var studentNames:     [String: String] = [:]
    @State private var selectedStudents: Set<String> = []
    @State private var assignmentTitle   = ""
    @State private var assignmentDesc    = ""

    @State private var isSaving     = false
    @State private var isAssigning  = false
    @State private var isLoadingRoster = true
    @State private var savedMessage: String?
    @State private var errorMessage: String?

    init(plan: DailyLessonPlan, teacherProfile: UserProfile, onSaved: @escaping () -> Void) {
        self.plan           = plan
        self.teacherProfile = teacherProfile
        self.onSaved        = onSaved
        _primaryText     = State(initialValue: plan.resolvedPrimaryText)
        _alternativeText = State(initialValue: plan.resolvedAlternativeText)
        _activities      = State(initialValue: plan.resolvedActivities.isEmpty
                                     ? ["", "", ""] : plan.resolvedActivities)
        _studentPrompt   = State(initialValue: plan.resolvedStudentPrompt)
        _teacherNotes    = State(initialValue: plan.teacherNotes)
        _assignmentTitle = State(initialValue: "\(plan.grade) ELA — \(plan.standardCode)")
        _assignmentDesc  = State(initialValue: "Complete Day \(plan.dayNumber) activities for \(plan.standardCode).")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                standardSection
                assignmentShellSection
                suggestedContentSection
                if plan.status == .approved || plan.status == .assigned {
                    assignSection
                }
                if let msg = savedMessage {
                    confirmationBanner(msg, color: .green)
                }
                if let err = errorMessage {
                    confirmationBanner(err, color: .red)
                }
            }
            .padding(20)
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Day \(plan.dayNumber) — \(plan.standardCode)")
        .inlineNavigationTitle()
        .task { await loadRoster() }
    }

    // MARK: - Standard Info

    private var standardSection: some View {
        DetailSection("Standard") {
            LabeledRow("Grade", plan.grade)
            LabeledRow("Standard", plan.standardCode)
            LabeledRow("Description", plan.standardDescription)
            if !plan.strand.isEmpty {
                LabeledRow("Strand", plan.strand)
            }
            StatusBadge(status: plan.status)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Student Assignment Shell (read-only)

    private var assignmentShellSection: some View {
        DetailSection("Student Assignment (Template)") {
            Text(plan.studentAssignment)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !plan.subStandards.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sub-Standards Practiced")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(plan.subStandards, id: \.self) { sub in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Suggested Content (editable)

    private var suggestedContentSection: some View {
        DetailSection(
            "Suggested Content",
            footer: "AI-generated draft — edit anything before accepting. Accepting saves your edits and unlocks Assign."
        ) {
            EditField("Primary Text") {
                TextField("Book title and author", text: $primaryText, axis: .vertical)
                    .lineLimit(2...3)
            }
            EditField("Alternative Text") {
                TextField("Alternative book or article", text: $alternativeText, axis: .vertical)
                    .lineLimit(2...3)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Activities")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(activities.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(i + 1).")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        TextField("Activity \(i + 1)", text: $activities[i], axis: .vertical)
                            .lineLimit(3...6)
                            .font(.subheadline)
                    }
                }
            }

            EditField("Student Prompt") {
                TextField("Student-facing prompt", text: $studentPrompt, axis: .vertical)
                    .lineLimit(3...6)
            }

            EditField("Teacher Notes (optional)") {
                TextField("Pacing, accommodations, context…", text: $teacherNotes, axis: .vertical)
                    .lineLimit(2...4)
            }

            Button(action: accept) {
                if isSaving {
                    HStack(spacing: 8) { ProgressView(); Text("Saving…") }
                        .frame(maxWidth: .infinity)
                } else {
                    Label(
                        plan.status == .draft ? "Accept Suggestions" : "Save Changes",
                        systemImage: plan.status == .draft ? "checkmark.circle.fill" : "square.and.pencil"
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving || primaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Assign Section

    private var assignSection: some View {
        DetailSection(
            "Assign to Students",
            footer: "EduAssist creates a content item and a learning path for each selected student."
        ) {
            EditField("Assignment Title") {
                TextField("Assignment title", text: $assignmentTitle)
            }
            EditField("Student-Facing Description") {
                TextField("What students will see", text: $assignmentDesc, axis: .vertical)
                    .lineLimit(2...3)
            }

            if isLoadingRoster {
                ProgressView("Loading class roster…")
            } else if linkedStudents.isEmpty {
                Label("No confirmed students linked yet.", systemImage: "person.badge.plus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(linkedStudents) { link in
                        StudentToggleRow(
                            name:       studentNames[link.studentId] ?? link.studentEmail,
                            email:      link.studentEmail,
                            isSelected: selectedStudents.contains(link.studentId)
                        ) {
                            if selectedStudents.contains(link.studentId) {
                                selectedStudents.remove(link.studentId)
                            } else {
                                selectedStudents.insert(link.studentId)
                            }
                        }
                    }
                }
            }

            Button(action: assign) {
                if isAssigning {
                    HStack(spacing: 8) { ProgressView(); Text("Assigning…") }
                        .frame(maxWidth: .infinity)
                } else {
                    Label(
                        "Assign to \(selectedStudents.count) Student\(selectedStudents.count == 1 ? "" : "s")",
                        systemImage: "paperplane.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAssign)
        }
    }

    private var canAssign: Bool {
        !isAssigning &&
        !selectedStudents.isEmpty &&
        !assignmentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        plan.status != .draft
    }

    // MARK: - Actions

    private func accept() {
        guard !isSaving else { return }
        isSaving = true
        savedMessage = nil
        errorMessage = nil
        Task {
            defer { isSaving = false }
            do {
                try await FirestoreService.shared.saveDailyLessonPlanEdits(
                    id:                   plan.id,
                    editedPrimaryText:    primaryText.trimmingCharacters(in: .whitespacesAndNewlines),
                    editedAlternativeText: alternativeText.trimmingCharacters(in: .whitespacesAndNewlines),
                    editedActivities:     activities.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
                    editedStudentPrompt:  studentPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
                    teacherNotes:         teacherNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                    status:               .approved
                )
                savedMessage = "Saved — plan is now ready to assign."
                onSaved()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func assign() {
        guard canAssign else { return }
        isAssigning = true
        savedMessage = nil
        errorMessage = nil
        Task {
            defer { isAssigning = false }
            do {
                let planText = composedPlanText()
                let dayRec = CloudFunctionService.LessonDayRecommendation(
                    id:             plan.id,
                    dayNumber:      plan.dayNumber,
                    title:          assignmentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    rationale:      "Day \(plan.dayNumber) — \(plan.standardCode): \(plan.standardDescription)",
                    lessonPlanText: planText
                )
                let result = try await CloudFunctionService.shared.assignLessonPlan(
                    title:       assignmentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: assignmentDesc.trimmingCharacters(in: .whitespacesAndNewlines),
                    grade:       plan.gradeLevel,
                    subject:     plan.subject,
                    standard:    plan.standardCode,
                    lessonPlan:  planText,
                    documentId:  nil,
                    dailyPlans:  [dayRec],
                    studentIds:  Array(selectedStudents)
                )
                try await FirestoreService.shared.saveDailyLessonPlanEdits(
                    id:                   plan.id,
                    editedPrimaryText:    primaryText,
                    editedAlternativeText: alternativeText,
                    editedActivities:     activities.filter { !$0.isEmpty },
                    editedStudentPrompt:  studentPrompt,
                    teacherNotes:         teacherNotes,
                    status:               .assigned
                )
                savedMessage = "Assigned to \(result.assignedCount) student\(result.assignedCount == 1 ? "" : "s")."
                onSaved()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func composedPlanText() -> String {
        var parts: [String] = [
            "# \(plan.grade) ELA — \(plan.standardCode)",
            "",
            "**Standard:** \(plan.standardDescription)",
            "",
            "## Text",
            "**Primary:** \(primaryText)",
            "**Alternative:** \(alternativeText)",
            "",
            "## Activities",
        ]
        for (i, a) in activities.enumerated() where !a.isEmpty {
            parts.append("\(i + 1). \(a)")
        }
        parts += ["", "## Student Prompt", studentPrompt]
        if !teacherNotes.isEmpty {
            parts += ["", "## Teacher Notes", teacherNotes]
        }
        return parts.joined(separator: "\n")
    }

    // MARK: - Roster

    private func loadRoster() async {
        isLoadingRoster = true
        let links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id))
            ?? []
        linkedStudents = links.filter(\.confirmed)
        selectedStudents = Set(linkedStudents.map(\.studentId))

        var names: [String: String] = [:]
        await withTaskGroup(of: (String, String?).self) { group in
            for link in linkedStudents {
                group.addTask {
                    let p = try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId)
                    return (link.studentId, p?.displayName)
                }
            }
            for await (sid, name) in group {
                if let name { names[sid] = name }
            }
        }
        studentNames = names
        isLoadingRoster = false
    }

    // MARK: - Confirmation banner

    private func confirmationBanner(_ msg: String, color: Color) -> some View {
        Label(msg, systemImage: color == .green ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Reusable sub-views

private struct DetailSection<Content: View>: View {
    let title: String
    let footer: String?
    @ViewBuilder let content: Content

    init(_ title: String, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title   = title
        self.footer  = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryGroupedBackground, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EditField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title   = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String
    init(_ label: String, _ value: String) { self.label = label; self.value = value }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)
            Text(value)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StudentToggleRow: View {
    let name: String
    let email: String
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.subheadline)
                    Text(email).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
