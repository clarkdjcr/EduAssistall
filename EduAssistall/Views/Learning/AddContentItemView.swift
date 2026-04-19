import SwiftUI

struct AddContentItemView: View {
    let teacherId: String
    let onAdd: (ContentItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var contentType: ContentType = .video
    @State private var url = ""
    @State private var subject = ""
    @State private var gradeLevel = ""
    @State private var estimatedMinutes = 10
    @State private var pendingQuizItem: ContentItem?
    @State private var showCatalog = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Content Details") {
                    TextField("Title", text: $title)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3)

                    Picker("Type", selection: $contentType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                }

                if contentType != .quiz {
                    Section("URL") {
                        TextField(
                            contentType == .video ? "YouTube or video URL" : "Article URL",
                            text: $url
                        )
                        .emailInput() // reuses autocorrectionDisabled

                        Button {
                            showCatalog = true
                        } label: {
                            Label("Browse Khan Academy Catalog", systemImage: "safari.fill")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                Section("Metadata") {
                    TextField("Subject (e.g. Math, Science)", text: $subject)

                    TextField("Grade Level (e.g. 6, 10, K)", text: $gradeLevel)

                    Stepper("Estimated time: \(estimatedMinutes) min",
                            value: $estimatedMinutes, in: 1...120, step: 5)
                }
            }
            .navigationTitle("Add Content Item")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add") {
                        let item = ContentItem(
                            title: title,
                            description: description,
                            contentType: contentType,
                            url: url,
                            subject: subject,
                            gradeLevel: gradeLevel,
                            estimatedMinutes: estimatedMinutes,
                            createdBy: teacherId
                        )
                        onAdd(item)
                        if contentType == .quiz {
                            pendingQuizItem = item
                        } else {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .fullScreenCover(item: $pendingQuizItem) { quizItem in
                ManageQuizQuestionsView(item: quizItem, teacherId: teacherId) {
                    pendingQuizItem = nil
                    dismiss()
                }
            }
            .sheet(isPresented: $showCatalog) {
                ContentCatalogView(teacherId: teacherId, gradeLevel: gradeLevel) { imported in
                    onAdd(imported)
                    dismiss()
                }
            }
        }
    }
}
