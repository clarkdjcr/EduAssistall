import SwiftUI

struct GenerateLessonPlanView: View {
    let teacherProfile: UserProfile

    private static let grades = ["K", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    private static let subjects = ["ELA", "Math", "Science", "Social Studies", "Art", "Music", "PE", "Technology", "Other"]
    private static let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    private static let resourceProviders = [
        VendorResourceProvider(id: "khanacademy", name: "Khan Academy", detail: "Videos and articles"),
        VendorResourceProvider(id: "edx", name: "edX", detail: "Introductory courses"),
        VendorResourceProvider(id: "nasa", name: "NASA STEM", detail: "STEM activities and articles"),
    ]

    @Environment(\.dismiss) private var dismiss

    @State private var grade = "5"
    @State private var subject = "Math"
    @State private var topic = ""
    @State private var standard = ""
    @State private var durationMinutes = 45
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
    @State private var selectedWeekdays = Set(Self.weekdays)
    @State private var supplementalResources = ""
    @State private var selectedResourceProvider = "khanacademy"
    @State private var vendorResources: [CatalogItem] = []
    @State private var selectedVendorResourceIds = Set<String>()
    @State private var teacherNotes = ""
    @State private var appliedWikiCount = 0

    @State private var bookSuggestions: [BookSuggestion] = []
    @State private var selectedBookTitle: String?
    @State private var customBookTitle = ""
    @State private var isLoadingBookSuggestions = false
    @State private var bookSuggestionMessage: String?

    @State private var curriculumDocs: [CurriculumDocEntry] = []
    @State private var selectedCurriculumId: String?
    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var selectedStudentIds = Set<String>()

    @State private var result: CloudFunctionService.LessonPlanResult?
    @State private var generatedPlan = ""
    @State private var dailyRecommendations: [CloudFunctionService.LessonDayRecommendation] = []
    @State private var approvedDayIds = Set<String>()
    @State private var assignmentTitle = ""
    @State private var assignmentDescription = ""
    @State private var assignedCount: Int?
    @State private var isLoadingWorkspace = true
    @State private var isLoadingVendorResources = false
    @State private var isGenerating = false
    @State private var isParsingDays = false
    @State private var isAssigning = false
    @State private var errorMessage: String?
    @State private var assignmentMessage: String?
    @State private var dailyRecommendationMessage: String?
    @State private var vendorResourceMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    workspaceProgressSection
                    lessonDetailsSection
                    if subject == "ELA" {
                        bookChoiceSection
                    }
                    teachingWindowSection
                    amplifyingSourcesSection
                    generateSection

                    if !generatedPlan.isEmpty {
                        reviewSection
                    }

                    if !dailyRecommendations.isEmpty {
                        dailyRecommendationsSection
                    }

                    if canShowAssignment {
                        assignmentSection
                    }

                    if let errorMessage {
                        LessonWorkspaceSection {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 1040)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Lesson Workspace")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: startDate) { _, newValue in
                if endDate < newValue {
                    endDate = newValue
                }
            }
            .onChange(of: endDate) { _, newValue in
                if newValue < startDate {
                    startDate = newValue
                }
            }
            .onChange(of: subject) { _, _ in
                resetVendorResourcesAfterLessonChange()
                resetBookSuggestionsAfterLessonChange()
            }
            .onChange(of: grade) { _, _ in
                resetVendorResourcesAfterLessonChange()
                resetBookSuggestionsAfterLessonChange()
            }
            .task { await loadWorkspaceData() }
        }
    }

    private var workspaceProgressSection: some View {
        LessonWorkspaceSection {
            HStack(spacing: 12) {
                WorkspaceStep(number: 1, title: "Plan", isActive: generatedPlan.isEmpty)
                WorkspaceStep(number: 2, title: "Approve", isActive: !generatedPlan.isEmpty && dailyRecommendations.isEmpty)
                WorkspaceStep(number: 3, title: "Days", isActive: !dailyRecommendations.isEmpty && !allDaysApproved)
                WorkspaceStep(number: 4, title: "Assign", isActive: allDaysApproved || assignedCount != nil)
            }
            .padding(.vertical, 6)
        }
    }

    private var lessonDetailsSection: some View {
        LessonWorkspaceSection("Approved Curriculum") {
            LessonField("Grade") {
                Picker("Grade", selection: $grade) {
                    ForEach(Self.grades, id: \.self) { Text("Grade \($0)").tag($0) }
                }
                .labelsHidden()
            }
            LessonField("Subject") {
                Picker("Subject", selection: $subject) {
                    ForEach(Self.subjects, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
            }

            if isLoadingWorkspace {
                ProgressView("Loading curriculum and roster...")
            } else if matchingCurriculumDocs.isEmpty {
                Label("No matching curriculum source found. The plan can still use the typed standard and district library search.", systemImage: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Source", selection: $selectedCurriculumId) {
                    Text("Auto-match best source").tag(String?.none)
                    ForEach(matchingCurriculumDocs) { doc in
                        Text(sourceTitle(doc)).tag(Optional(doc.id))
                    }
                }
                .onChange(of: selectedCurriculumId) { _, newValue in
                    applyCurriculumSelection(newValue)
                }
            }

            LessonField("Topic") {
                TextField("e.g. Place Value, Cell Division", text: $topic)
                    .nameInput()
            }
            LessonField("Standard") {
                TextField("Optional, e.g. 5.NBT.A.1", text: $standard)
                    .nameInput()
            }
            Stepper("\(durationMinutes) minutes per class period", value: $durationMinutes, in: 30...90, step: 5)
        }
    }

    private var bookChoiceSection: some View {
        LessonWorkspaceSection(
            "Primary Text",
            footer: "Optional — pick a book or supply your own. If you skip this, the AI chooses the text itself, just like today."
        ) {
            Button(action: suggestBooks) {
                if isLoadingBookSuggestions {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Suggesting Books...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Suggest Books for This Topic", systemImage: "book.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(isLoadingBookSuggestions || topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !bookSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Books")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(bookSuggestions) { book in
                        BookSuggestionToggle(
                            book: book,
                            isSelected: selectedBookTitle == book.title
                        ) {
                            selectedBookTitle = book.title
                            customBookTitle = ""
                        }
                    }
                }
            }

            if let bookSuggestionMessage {
                Label(bookSuggestionMessage, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LessonField("Or type your own book/material") {
                TextField("e.g. Charlotte's Web by E.B. White", text: $customBookTitle)
                    .nameInput()
                    .onChange(of: customBookTitle) { _, newValue in
                        if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            selectedBookTitle = nil
                        }
                    }
            }
        }
    }

    private var teachingWindowSection: some View {
        LessonWorkspaceSection("Teaching Window") {
            DatePicker("Start", selection: $startDate, displayedComponents: .date)
            DatePicker("End", selection: $endDate, displayedComponents: .date)
            VStack(alignment: .leading, spacing: 10) {
                Text("Class Meets")
                    .font(.subheadline)
                WeekdaySelector(selectedWeekdays: $selectedWeekdays, weekdays: Self.weekdays)
                Text("\(availableTeachingDays) teaching day\(availableTeachingDays == 1 ? "" : "s") available")
                    .font(.caption)
                    .foregroundStyle(availableTeachingDays == 0 ? .red : .secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var amplifyingSourcesSection: some View {
        LessonWorkspaceSection(
            "Amplifying Sources",
            footer: "The plan is grounded in approved curriculum first. Selected provider resources and teacher notes amplify the lesson but do not replace standards."
        ) {
            LessonField("Provider resources") {
                Picker("Provider", selection: $selectedResourceProvider) {
                    ForEach(Self.resourceProviders) { provider in
                        Text(provider.name).tag(provider.id)
                    }
                }
                .labelsHidden()
                .onChange(of: selectedResourceProvider) { _, _ in
                    vendorResources = []
                    selectedVendorResourceIds.removeAll()
                    vendorResourceMessage = nil
                }

                Button(action: loadVendorResources) {
                    if isLoadingVendorResources {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Searching Resources...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Label("Find \(selectedProviderName) Resources for \(subject)", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoadingVendorResources)

                Text(selectedProviderDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !vendorResources.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Resources")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(vendorResources) { item in
                        VendorResourceToggle(
                            item: item,
                            isSelected: selectedVendorResourceIds.contains(item.id)
                        ) {
                            toggleVendorResource(item.id)
                        }
                    }
                }
            }

            if let vendorResourceMessage {
                Label(vendorResourceMessage, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LessonField("Videos, articles, current events, or links") {
                TextField("Add links or resource notes", text: $supplementalResources, axis: .vertical)
                    .lineLimit(3...6)
            }
            LessonField("Teacher notes, pacing constraints, or class context") {
                TextField("Add notes for pacing, grouping, accommodations, or context", text: $teacherNotes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    private var generateSection: some View {
        LessonWorkspaceSection {
            Button(action: generate) {
                if isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Generating Plan...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label(generatedPlan.isEmpty ? "Generate Lesson Plan" : "Regenerate Lesson Plan", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canGenerate)
        }
    }

    private var reviewSection: some View {
        LessonWorkspaceSection(
            "Teacher Review",
            footer: "Edit the AI recommendation here. Approving the plan does not send anything to students; it creates teaching-day recommendations for a second review."
        ) {
            if result?.documentId != nil {
                Label("Saved as a draft document for review", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            if appliedWikiCount > 0 {
                Label("\(appliedWikiCount) wiki insight\(appliedWikiCount == 1 ? "" : "s") applied from your Teaching Wiki", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            TextEditor(text: $generatedPlan)
                .frame(minHeight: 260)
                .font(.body)
            ShareLink(
                item: generatedPlan,
                subject: Text(assignmentTitle.isEmpty ? "EduAssist Lesson Plan" : assignmentTitle),
                message: Text("Draft lesson plan from EduAssist")
            )

            if let dailyRecommendationMessage {
                Label(dailyRecommendationMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            Button(action: approvePlanAndBuildDays) {
                if isParsingDays {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Building Daily Recommendations...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label(dailyRecommendations.isEmpty ? "Approve Plan and Build Days" : "Rebuild Daily Recommendations", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canApprovePlan)
        }
    }

    private var dailyRecommendationsSection: some View {
        LessonWorkspaceSection(
            "Daily AI Recommendations",
            footer: "Review each AI-parsed teaching day. These are teacher-only drafts until you approve every day and create student assignments below."
        ) {
            Label(
                allDaysApproved
                    ? "Daily lessons are approved. Use Assign below to create student learning paths."
                    : "Not sent yet. Students will not see these daily lessons until you approve them and assign them.",
                systemImage: allDaysApproved ? "paperplane.circle.fill" : "lock.fill"
            )
            .font(.subheadline)
            .foregroundStyle(allDaysApproved ? .green : .secondary)
            .fixedSize(horizontal: false, vertical: true)

            ForEach(dailyRecommendations) { day in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("Day \(day.dayNumber)", systemImage: "calendar")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        Spacer()
                        if approvedDayIds.contains(day.id) {
                            Label("Approved", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }

                    Text(day.title)
                        .font(.subheadline.bold())
                    if !day.rationale.isEmpty {
                        Text(day.rationale)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    TextEditor(text: dailyPlanTextBinding(for: day.id))
                        .frame(minHeight: 160)
                        .font(.body)

                    Button {
                        approvedDayIds.insert(day.id)
                    } label: {
                        Label(approvedDayIds.contains(day.id) ? "Day Approved" : "Approve Day", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(approvedDayIds.contains(day.id))
                }
                .padding(12)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                approvedDayIds = Set(dailyRecommendations.map(\.id))
            } label: {
                Label("Approve All Days", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(allDaysApproved)
        }
    }

    private var assignmentSection: some View {
        LessonWorkspaceSection(
            "Assign",
            footer: "EduAssist creates reviewed daily lesson content and an active learning path for each selected student. Students see the approved daily assignments, not the raw lesson plan."
        ) {
            LessonField("Assignment title") {
                TextField("Assignment title", text: $assignmentTitle)
            }
            LessonField("Student-facing description") {
                TextField("Student-facing description", text: $assignmentDescription, axis: .vertical)
                    .lineLimit(2...4)
            }

            if linkedStudents.isEmpty {
                Text("No confirmed students are available yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(linkedStudents) { link in
                    StudentAssignmentToggle(
                        link: link,
                        displayName: studentNames[link.studentId],
                        isSelected: selectedStudentIds.contains(link.studentId)
                    ) {
                        toggleStudent(link.studentId)
                    }
                }
            }

            if let assignmentMessage {
                Label(assignmentMessage, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }

            Button(action: assign) {
                if isAssigning {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Assigning...")
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Label("Create Student Assignment\(selectedStudentIds.count == 1 ? "" : "s") for \(selectedStudentIds.count)", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAssign)
        }
    }

    private var canGenerate: Bool {
        !topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        availableTeachingDays > 0 &&
        !isGenerating
    }

    private var canAssign: Bool {
        !generatedPlan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !assignmentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedStudentIds.isEmpty &&
        allDaysApproved &&
        !isAssigning
    }

    private var canApprovePlan: Bool {
        !generatedPlan.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isParsingDays
    }

    private var allDaysApproved: Bool {
        !dailyRecommendations.isEmpty && approvedDayIds.count == dailyRecommendations.count
    }

    private var canShowAssignment: Bool {
        allDaysApproved || assignedCount != nil
    }

    private var matchingCurriculumDocs: [CurriculumDocEntry] {
        curriculumDocs.filter { doc in
            gradeMatches(doc.gradeLevel, selectedGrade: grade) && subjectMatches(doc.subject, selectedSubject: subject)
        }
    }

    private var selectedProviderName: String {
        Self.resourceProviders.first(where: { $0.id == selectedResourceProvider })?.name ?? "Provider"
    }

    private var selectedProviderDetail: String {
        Self.resourceProviders.first(where: { $0.id == selectedResourceProvider })?.detail ?? ""
    }

    private var selectedVendorResources: [CatalogItem] {
        vendorResources.filter { selectedVendorResourceIds.contains($0.id) }
    }

    private var chosenBookContext: String? {
        let custom = customBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !custom.isEmpty {
            return "Primary text/book for this lesson (teacher-supplied): \(custom)"
        }
        guard let selectedBookTitle,
              let book = bookSuggestions.first(where: { $0.title == selectedBookTitle }) else { return nil }
        let authorPart = book.author.isEmpty ? "" : " by \(book.author)"
        return "Primary text/book for this lesson: \"\(book.title)\"\(authorPart) — \(book.rationale)"
    }

    private var resourceContextForGeneration: String {
        var parts: [String] = []
        if let chosenBookContext {
            parts.append(chosenBookContext)
        }
        if !selectedVendorResources.isEmpty {
            let selected = selectedVendorResources.map { item in
                "- \(providerDisplayName(item.source)): \(item.title)\n  \(item.description)\n  \(item.url)"
            }
            parts.append("Teacher-selected provider resources:\n\(selected.joined(separator: "\n"))")
        }
        let typed = supplementalResources.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty {
            parts.append("Teacher-entered resources and links:\n\(typed)")
        }
        return parts.joined(separator: "\n\n")
    }

    private func loadWorkspaceData() async {
        isLoadingWorkspace = true
        async let docs = FirestoreService.shared.fetchCurriculumDocuments()
        async let links = FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id)

        curriculumDocs = (try? await docs) ?? []
        linkedStudents = ((try? await links) ?? []).filter(\.confirmed)
        selectedStudentIds = Set(linkedStudents.map(\.studentId))

        var names: [String: String] = [:]
        await withTaskGroup(of: (String, String?).self) { group in
            for link in linkedStudents {
                group.addTask {
                    let profile = try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId)
                    return (link.studentId, profile?.displayName)
                }
            }
            for await (studentId, name) in group {
                if let name { names[studentId] = name }
            }
        }
        studentNames = names
        isLoadingWorkspace = false
    }

    private func generate() {
        errorMessage = nil
        assignmentMessage = nil
        isGenerating = true
        Task {
            defer { isGenerating = false }
            do {
                let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedStandard = standard.trimmingCharacters(in: .whitespacesAndNewlines)
                let wikiDigest = await buildWikiDigest(standard: trimmedStandard)
                let planResult = try await CloudFunctionService.shared.generateLessonPlan(
                    grade: grade,
                    subject: subject,
                    topic: trimmedTopic,
                    durationMinutes: durationMinutes,
                    standard: trimmedStandard,
                    startDate: startDate,
                    endDate: endDate,
                    teachingDays: Self.weekdays.filter { selectedWeekdays.contains($0) },
                    supplementalResources: resourceContextForGeneration,
                    teacherNotes: teacherNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                    teacherWikiDigest: wikiDigest
                )
                result = planResult
                generatedPlan = planResult.lessonPlan
                dailyRecommendations = []
                approvedDayIds.removeAll()
                assignmentTitle = "\(subject) - \(trimmedTopic)"
                assignmentDescription = "Complete the reviewed lesson plan activities for \(trimmedTopic)."
                assignedCount = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Selects the teacher's relevant wiki entries by metadata, compresses them on-device,
    /// and returns a compact digest to ground generation. Returns "" when nothing applies.
    /// Updates `appliedWikiCount` for the UI indicator.
    private func buildWikiDigest(standard: String) async -> String {
        let codes = standard.isEmpty ? [] : [standard]
        let selected = (try? await FirestoreService.shared.selectWikiEntries(
            teacherId: teacherProfile.id,
            subject: subject,
            grade: grade,
            standardCodes: codes
        )) ?? []
        appliedWikiCount = selected.count
        guard !selected.isEmpty else { return "" }
        return await TeacherKnowledgeAIService.shared.buildDigest(from: selected) ?? ""
    }

    private func approvePlanAndBuildDays() {
        errorMessage = nil
        dailyRecommendationMessage = nil
        isParsingDays = true
        Task {
            defer { isParsingDays = false }
            do {
                let days = try await CloudFunctionService.shared.approveLessonPlanAndGenerateDays(
                    recommendationId: result?.recommendationId,
                    title: assignmentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(subject) - \(topic)" : assignmentTitle,
                    grade: grade,
                    subject: subject,
                    standard: standard.trimmingCharacters(in: .whitespacesAndNewlines),
                    lessonPlan: generatedPlan.trimmingCharacters(in: .whitespacesAndNewlines),
                    startDate: startDate,
                    endDate: endDate,
                    teachingDays: Self.weekdays.filter { selectedWeekdays.contains($0) }
                )
                dailyRecommendations = days.sorted { $0.dayNumber < $1.dayNumber }
                approvedDayIds.removeAll()
                dailyRecommendationMessage = "Created \(days.count) daily recommendation\(days.count == 1 ? "" : "s"). Review and approve each day, then create student assignments below."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func loadVendorResources() {
        vendorResourceMessage = nil
        isLoadingVendorResources = true
        Task {
            defer { isLoadingVendorResources = false }
            do {
                let items = try await CloudFunctionService.shared.curateContent(
                    subject: subject,
                    gradeLevel: grade,
                    source: selectedResourceProvider
                )
                vendorResources = items
                selectedVendorResourceIds = Set(items.prefix(3).map(\.id))
                vendorResourceMessage = items.isEmpty
                    ? "No provider resources were returned for this subject."
                    : "\(items.count) resources found. The first \(min(3, items.count)) are selected."
            } catch {
                vendorResourceMessage = "Could not load \(selectedProviderName) resources: \(error.localizedDescription)"
            }
        }
    }

    private func suggestBooks() {
        bookSuggestionMessage = nil
        isLoadingBookSuggestions = true
        Task {
            defer { isLoadingBookSuggestions = false }
            do {
                let items = try await CloudFunctionService.shared.suggestLessonMaterials(
                    grade: grade,
                    topic: topic.trimmingCharacters(in: .whitespacesAndNewlines),
                    standard: standard.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                bookSuggestions = items
                selectedBookTitle = items.first?.title
                customBookTitle = ""
                bookSuggestionMessage = items.isEmpty ? "No book suggestions were returned for this topic." : nil
            } catch {
                bookSuggestionMessage = "Could not load book suggestions: \(error.localizedDescription)"
            }
        }
    }

    private func assign() {
        errorMessage = nil
        assignmentMessage = nil
        isAssigning = true
        Task {
            defer { isAssigning = false }
            do {
                let response = try await CloudFunctionService.shared.assignLessonPlan(
                    title: assignmentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: assignmentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    grade: grade,
                    subject: subject,
                    standard: standard.trimmingCharacters(in: .whitespacesAndNewlines),
                    lessonPlan: generatedPlan.trimmingCharacters(in: .whitespacesAndNewlines),
                    documentId: result?.documentId,
                    dailyPlans: approvedDailyRecommendations,
                    studentIds: Array(selectedStudentIds),
                    weekOf: startDate
                )
                assignedCount = response.assignedCount
                assignmentMessage = "Created daily lesson assignment\(response.assignedCount == 1 ? "" : "s") for \(response.assignedCount) student\(response.assignedCount == 1 ? "" : "s"). Students can open the approved work in Learning."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private var approvedDailyRecommendations: [CloudFunctionService.LessonDayRecommendation] {
        dailyRecommendations
            .filter { approvedDayIds.contains($0.id) }
            .sorted { $0.dayNumber < $1.dayNumber }
    }

    private func dailyPlanTextBinding(for id: String) -> Binding<String> {
        Binding(
            get: {
                dailyRecommendations.first(where: { $0.id == id })?.lessonPlanText ?? ""
            },
            set: { newValue in
                if let index = dailyRecommendations.firstIndex(where: { $0.id == id }) {
                    dailyRecommendations[index].lessonPlanText = newValue
                    approvedDayIds.remove(id)
                }
            }
        )
    }

    private var availableTeachingDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        guard start <= end else { return 0 }

        var count = 0
        var current = start
        while current <= end {
            let weekday = calendar.component(.weekday, from: current)
            let label = weekdayLabel(for: weekday)
            if selectedWeekdays.contains(label) {
                count += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return count
    }

    private func weekdayLabel(for weekday: Int) -> String {
        switch weekday {
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        default: return ""
        }
    }

    private func sourceTitle(_ doc: CurriculumDocEntry) -> String {
        if doc.standard.isEmpty {
            return doc.title
        }
        return "\(doc.standard) - \(doc.title)"
    }

    private func applyCurriculumSelection(_ id: String?) {
        guard let id, let doc = curriculumDocs.first(where: { $0.id == id }) else { return }
        if !doc.standard.isEmpty { standard = doc.standard }
        if topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            topic = doc.title
        }
    }

    private func toggleStudent(_ studentId: String) {
        if selectedStudentIds.contains(studentId) {
            selectedStudentIds.remove(studentId)
        } else {
            selectedStudentIds.insert(studentId)
        }
    }

    private func toggleVendorResource(_ resourceId: String) {
        if selectedVendorResourceIds.contains(resourceId) {
            selectedVendorResourceIds.remove(resourceId)
        } else {
            selectedVendorResourceIds.insert(resourceId)
        }
    }

    private func resetVendorResourcesAfterLessonChange() {
        vendorResources = []
        selectedVendorResourceIds.removeAll()
        vendorResourceMessage = "Resource results were cleared because the lesson subject or grade changed."
    }

    private func resetBookSuggestionsAfterLessonChange() {
        bookSuggestions = []
        selectedBookTitle = nil
        customBookTitle = ""
        bookSuggestionMessage = nil
    }

    private func providerDisplayName(_ source: String) -> String {
        switch source {
        case "khanacademy": return "Khan Academy"
        case "edx": return "edX"
        case "nasa": return "NASA STEM"
        default: return source
        }
    }

    private func gradeMatches(_ value: String, selectedGrade: String) -> Bool {
        let normalized = value.lowercased()
        if normalized.isEmpty { return true }
        if selectedGrade == "K" {
            return normalized.contains("k") || normalized.contains("kindergarten")
        }
        return normalized == selectedGrade ||
            normalized.contains("grade \(selectedGrade)") ||
            normalized.contains("grades \(selectedGrade)") ||
            normalized.contains("\(selectedGrade)-")
    }

    private func subjectMatches(_ value: String, selectedSubject: String) -> Bool {
        let normalized = value.lowercased()
        let selected = selectedSubject.lowercased()
        if normalized.isEmpty { return true }
        if selected == "ela" {
            return normalized.contains("english") || normalized.contains("language arts") || normalized.contains("ela")
        }
        if selected == "math" {
            return normalized.contains("math")
        }
        if selected == "pe" {
            return normalized.contains("physical") || normalized.contains("health")
        }
        return normalized.contains(selected)
    }
}

private struct VendorResourceProvider: Identifiable {
    let id: String
    let name: String
    let detail: String
}

private struct WorkspaceStep: View {
    let number: Int
    let title: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(isActive ? .white : .secondary)
                .frame(width: 24, height: 24)
                .background(isActive ? Color.blue : Color.secondary.opacity(0.14), in: Circle())
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LessonWorkspaceSection<Content: View>: View {
    let title: String?
    let footer: String?
    @ViewBuilder let content: Content

    init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.headline)
            }
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

private struct LessonField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StudentAssignmentToggle: View {
    let link: StudentAdultLink
    let displayName: String?
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName ?? link.studentEmail)
                        .font(.subheadline)
                    if displayName != nil {
                        Text(link.studentEmail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct BookSuggestionToggle: View {
    let book: BookSuggestion
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(book.author.isEmpty ? book.title : "\(book.title) — \(book.author)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !book.rationale.isEmpty {
                        Text(book.rationale)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(book.title)")
    }
}

private struct VendorResourceToggle: View {
    let item: CatalogItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Label(providerName, systemImage: iconName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("\(item.estimatedMinutes) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSecondaryBackground, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isSelected ? "Remove" : "Add") \(item.title)")
    }

    private var providerName: String {
        switch item.source {
        case "khanacademy": return "Khan Academy"
        case "edx": return "edX"
        case "nasa": return "NASA STEM"
        default: return item.source
        }
    }

    private var iconName: String {
        switch item.contentType {
        case "video": return "play.rectangle.fill"
        case "article": return "doc.text.fill"
        default: return "link"
        }
    }
}

private struct WeekdaySelector: View {
    @Binding var selectedWeekdays: Set<String>
    let weekdays: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 8)], spacing: 8) {
            ForEach(weekdays, id: \.self) { weekday in
                Button {
                    if selectedWeekdays.contains(weekday) {
                        selectedWeekdays.remove(weekday)
                    } else {
                        selectedWeekdays.insert(weekday)
                    }
                } label: {
                    Text(weekday)
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedWeekdays.contains(weekday) ? Color.blue : Color.appSecondaryBackground)
                        .foregroundStyle(selectedWeekdays.contains(weekday) ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
