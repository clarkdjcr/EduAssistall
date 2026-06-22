import SwiftUI
#if os(iOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct BehaviorDocumentationView: View {
    let teacherProfile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var studentNames: [String: String] = [:]
    @State private var recentRecords: [TeacherDocumentationRecord] = []
    @State private var selectedStudentId = ""
    @State private var category: TeacherDocumentationCategory = .behavior
    @State private var occurredAt = Date()
    @State private var location = ""
    @State private var objectiveSummary = ""
    @State private var teacherAction = ""
    @State private var studentResponse = ""
    @State private var nextStep = ""
    @State private var followUpStatus: TeacherDocumentationFollowUpStatus = .needsFollowUp
    @State private var saveState: SaveState = .idle
    @State private var loadError: String?

    private enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)
    }

    private var selectedLink: StudentAdultLink? {
        linkedStudents.first { $0.studentId == selectedStudentId }
    }

    private var selectedStudentName: String {
        guard let selectedLink else { return "Whole class / not student-specific" }
        return studentNames[selectedLink.studentId] ?? selectedLink.studentEmail
    }

    private var canSave: Bool {
        !objectiveSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !teacherAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if let loadError {
                        Label(loadError, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    incidentForm
                    generatedSummarySection
                    recentRecordsSection
                }
                .padding(20)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Behavior Documentation")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if saveState == .saving {
                            ProgressView()
                        } else {
                            Label("Save", systemImage: "checkmark.circle")
                        }
                    }
                    .disabled(!canSave || saveState == .saving)
                }
            }
            .task { await load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Teacher-owned documentation", systemImage: "doc.text.fill")
                .font(.headline)
            Text("Capture objective facts, the support you provided, and the next step. EduAssist formats the note, but the teacher keeps the judgment.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var incidentForm: some View {
        DocumentationSection(title: "Incident Details", icon: "square.and.pencil") {
            Picker("Student", selection: $selectedStudentId) {
                Text("Whole class / not student-specific").tag("")
                ForEach(linkedStudents) { link in
                    Text(studentNames[link.studentId] ?? link.studentEmail).tag(link.studentId)
                }
            }
            Picker("Category", selection: $category) {
                ForEach(TeacherDocumentationCategory.allCases) { item in
                    Text(item.displayName).tag(item)
                }
            }
            .pickerStyle(.menu)
            DatePicker("When", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
            TextField("Location or class period", text: $location)
                .textFieldStyle(.roundedBorder)
            TextField("Objective summary: what happened?", text: $objectiveSummary, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
            TextField("Teacher action: what support or redirection did you provide?", text: $teacherAction, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
            TextField("Student response", text: $studentResponse, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            TextField("Next step or follow-up", text: $nextStep, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            Picker("Follow-up", selection: $followUpStatus) {
                ForEach(TeacherDocumentationFollowUpStatus.allCases) { item in
                    Text(item.displayName).tag(item)
                }
            }
        }
    }

    private var generatedSummarySection: some View {
        DocumentationSection(title: "Admin-Ready Summary", icon: "doc.plaintext") {
            Text(adminReadySummary)
                .font(.callout)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button {
                    copyToClipboard(adminReadySummary)
                } label: {
                    Label("Copy Summary", systemImage: "doc.on.doc")
                }
                .disabled(adminReadySummary.isEmpty)

                Spacer()

                switch saveState {
                case .idle:
                    EmptyView()
                case .saving:
                    Label("Saving...", systemImage: "hourglass")
                        .foregroundStyle(.secondary)
                case .saved:
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                case .failed(let message):
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            .font(.caption)
        }
    }

    private var recentRecordsSection: some View {
        DocumentationSection(title: "Recent Records", icon: "clock.arrow.circlepath") {
            if recentRecords.isEmpty {
                Text("No documentation records saved yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentRecords.prefix(5)) { record in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(record.category.displayName)
                                .font(.subheadline.bold())
                            Spacer()
                            Text(record.occurredAt, format: .dateTime.month().day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(record.studentName)
                            .font(.caption.weight(.semibold))
                        Text(record.objectiveSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var adminReadySummary: String {
        let summary = objectiveSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        let action = teacherAction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty || !action.isEmpty else { return "" }

        var lines: [String] = []
        lines.append("Student: \(selectedStudentName)")
        lines.append("Category: \(category.displayName)")
        lines.append("When: \(occurredAt.formatted(date: .abbreviated, time: .shortened))")
        if !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Location: \(location.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if !summary.isEmpty { lines.append("Objective summary: \(summary)") }
        if !action.isEmpty { lines.append("Teacher action: \(action)") }
        let response = studentResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if !response.isEmpty { lines.append("Student response: \(response)") }
        let followUp = nextStep.trimmingCharacters(in: .whitespacesAndNewlines)
        if !followUp.isEmpty { lines.append("Next step: \(followUp)") }
        lines.append("Follow-up status: \(followUpStatus.displayName)")
        lines.append("Note: This record documents teacher observations and actions. It is not an automated discipline decision.")
        return lines.joined(separator: "\n")
    }

    private func load() async {
        do {
            let links = try await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id)
                .filter { $0.confirmed }
            linkedStudents = links
            if selectedStudentId.isEmpty, let first = links.first {
                selectedStudentId = first.studentId
            }

            var names: [String: String] = [:]
            await withTaskGroup(of: (String, String)?.self) { group in
                for link in links {
                    group.addTask {
                        let profile = try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId)
                        return (link.studentId, profile?.displayName ?? link.studentEmail)
                    }
                }
                for await item in group {
                    if let item { names[item.0] = item.1 }
                }
            }
            studentNames = names
            recentRecords = (try? await FirestoreService.shared.fetchTeacherDocumentationRecords(teacherId: teacherProfile.id)) ?? []
        } catch {
            loadError = "Couldn't load documentation data: \(error.localizedDescription)"
        }
    }

    private func save() async {
        saveState = .saving
        let record = TeacherDocumentationRecord(
            teacherId: teacherProfile.id,
            teacherName: teacherProfile.displayName,
            studentId: selectedLink?.studentId,
            studentName: selectedStudentName,
            studentEmail: selectedLink?.studentEmail,
            category: category,
            occurredAt: occurredAt,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            objectiveSummary: objectiveSummary.trimmingCharacters(in: .whitespacesAndNewlines),
            teacherAction: teacherAction.trimmingCharacters(in: .whitespacesAndNewlines),
            studentResponse: studentResponse.trimmingCharacters(in: .whitespacesAndNewlines),
            nextStep: nextStep.trimmingCharacters(in: .whitespacesAndNewlines),
            followUpStatus: followUpStatus,
            adminReadySummary: adminReadySummary
        )
        do {
            try await FirestoreService.shared.saveTeacherDocumentationRecord(record)
            recentRecords.insert(record, at: 0)
            objectiveSummary = ""
            teacherAction = ""
            studentResponse = ""
            nextStep = ""
            saveState = .saved
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }

    private func copyToClipboard(_ text: String) {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

private struct DocumentationSection<Content: View>: View {
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
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
