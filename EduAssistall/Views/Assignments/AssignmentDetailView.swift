import SwiftUI

struct AssignmentDetailView: View {
    let assignment: WeeklyAssignment
    let profile: UserProfile

    @State private var criteria: [GradingCriteria] = []
    @State private var weights: GradeWeights?
    @State private var isLoading = true
    @State private var showSubmit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Label(assignment.dayLabel, systemImage: "calendar")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Text(assignment.title)
                        .font(.title2.bold())
                    Label("Assigned by \(assignment.teacherName)",
                          systemImage: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Lesson plan content
                VStack(alignment: .leading, spacing: 10) {
                    Text("Assignment")
                        .font(.headline)
                    Text(assignment.lessonPlanText)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Grading criteria
                if !isLoading {
                    gradingSection
                }

                // Submit button
                Button {
                    showSubmit = true
                } label: {
                    Label("Submit Work", systemImage: "paperplane.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Spacer(minLength: 32)
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(assignment.dayLabel)
        .inlineNavigationTitle()
        .sheet(isPresented: $showSubmit) {
            SubmitAssignmentView(assignment: assignment, profile: profile)
        }
        .task { await load() }
    }

    // MARK: - Grading section

    @ViewBuilder
    private var gradingSection: some View {
        if let w = weights {
            VStack(alignment: .leading, spacing: 12) {
                Text("Grading Breakdown")
                    .font(.headline)
                ForEach([
                    (AssignmentType.homework, w.homework),
                    (.quiz, w.quizzes),
                    (.groupActivity, w.groupActivities),
                    (.finalExam, w.finalExam)
                ], id: \.0) { type, pct in
                    WeightRow(type: type, percent: pct)
                }
            }
            .padding(16)
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }

        if !criteria.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Rubrics")
                    .font(.headline)
                ForEach(criteria) { c in
                    RubricCard(criteria: c)
                }
            }
        }
    }

    private func load() async {
        async let wFetch = FirestoreService.shared.fetchGradeWeights(teacherId: assignment.teacherId)
        async let cFetch = FirestoreService.shared.fetchGradingCriteria(teacherId: assignment.teacherId)
        weights = try? await wFetch
        criteria = (try? await cFetch) ?? []
        isLoading = false
    }
}

// MARK: - Weight Row

private struct WeightRow: View {
    let type: AssignmentType
    let percent: Double

    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(type.displayName)
                .font(.subheadline)
            Spacer()
            Text("\(Int(percent))%")
                .font(.subheadline.bold())
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Rubric Card

private struct RubricCard: View {
    let criteria: GradingCriteria

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: criteria.assignmentType.icon)
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(criteria.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("\(criteria.totalPoints) points total · \(criteria.assignmentType.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(criteria.rubricItems) { item in
                        HStack(alignment: .top) {
                            Text(item.criterion)
                                .font(.subheadline)
                            Spacer()
                            Text("\(item.maxPoints) pts")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }
                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if item.id != criteria.rubricItems.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(14)
                .background(Color.appSecondaryGroupedBackground.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Submit Assignment Sheet

struct SubmitAssignmentView: View {
    let assignment: WeeklyAssignment
    let profile: UserProfile

    @State private var note = ""
    @State private var pendingAttachments: [PendingAttachment] = []
    @State private var isSending = false
    @State private var didSend = false
    @Environment(\.dismiss) private var dismiss

    #if os(iOS)
    @State private var showImagePicker = false
    @State private var showFilePicker = false
    #endif

    struct PendingAttachment: Identifiable {
        let id = UUID()
        let filename: String
        let data: Data
        let mimeType: String

        var sizeLabel: String {
            let kb = Double(data.count) / 1024
            if kb < 1024 { return String(format: "%.0f KB", kb) }
            return String(format: "%.1f MB", kb / 1024)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note to Teacher (optional)") {
                    TextField("Describe what you completed…", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Attachments") {
                    ForEach(pendingAttachments) { att in
                        HStack {
                            Image(systemName: att.mimeType.hasPrefix("image/") ? "photo.fill" : "doc.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(att.filename).font(.subheadline)
                                Text(att.sizeLabel).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                pendingAttachments.removeAll { $0.id == att.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    #if os(iOS)
                    Button {
                        showImagePicker = true
                    } label: {
                        Label("Add Photo or File", systemImage: "paperclip")
                    }
                    #endif
                }

                Section {
                    Button {
                        Task { await send() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSending { ProgressView() }
                            else { Text("Send to Teacher").fontWeight(.semibold) }
                            Spacer()
                        }
                    }
                    .disabled(isSending || (note.trimmingCharacters(in: .whitespaces).isEmpty && pendingAttachments.isEmpty))
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .background(Color.appGroupedBackground)
            .navigationTitle("Submit: \(assignment.dayLabel)")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: adaptiveTopBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showImagePicker) {
                ImageAttachmentPicker { data, filename, mime in
                    pendingAttachments.append(PendingAttachment(filename: filename, data: data, mimeType: mime))
                }
            }
            #endif
        }
    }

    private func send() async {
        isSending = true
        // Upload attachments to Firebase Storage, then send message to teacher's thread.
        var uploaded: [MessageAttachment] = []
        for att in pendingAttachments {
            if let (ref, url) = try? await StorageService.shared.upload(
                data: att.data,
                path: StorageService.submissionPath(
                    studentId: profile.id,
                    threadId: assignment.teacherId,
                    filename: "\(assignment.id)_\(att.filename)"
                ),
                mimeType: att.mimeType
            ) {
                uploaded.append(MessageAttachment(
                    filename: att.filename, storageRef: ref,
                    downloadURL: url, mimeType: att.mimeType, sizeBytes: att.data.count
                ))
            }
        }
        let body = note.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Submission for \(assignment.dayLabel) — \(assignment.title)"
            : note.trimmingCharacters(in: .whitespaces)

        // Find or create message thread between student and teacher.
        let threadId = "\(assignment.teacherId)_\(profile.id)"
        let message = Message(
            threadId: threadId,
            senderId: profile.id,
            senderName: profile.displayName,
            body: body,
            attachments: uploaded
        )
        try? await FirestoreService.shared.sendMessage(message)
        isSending = false
        dismiss()
    }
}

// MARK: - Image Attachment Picker (iOS only)

#if os(iOS)
import PhotosUI

struct ImageAttachmentPicker: UIViewControllerRepresentable {
    let onPick: (Data, String, String) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .any(of: [.images, .screenshots])
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (Data, String, String) -> Void
        init(onPick: @escaping (Data, String, String) -> Void) { self.onPick = onPick }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                let provider = result.itemProvider
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { obj, _ in
                        guard let img = obj as? UIImage,
                              let data = img.jpegData(compressionQuality: 0.8) else { return }
                        let name = result.assetIdentifier?.components(separatedBy: "/").last
                            ?? "photo_\(UUID().uuidString.prefix(8)).jpg"
                        DispatchQueue.main.async {
                            self.onPick(data, name.hasSuffix(".jpg") ? name : name + ".jpg", "image/jpeg")
                        }
                    }
                }
            }
        }
    }
}
#endif
