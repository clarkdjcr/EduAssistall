import SwiftUI
import UniformTypeIdentifiers

struct CurriculumLibraryView: View {
    let profile: UserProfile

    @State private var documents: [CurriculumDocEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showUpload = false
    @State private var deleteError: String?

    private var curriculumDocs: [CurriculumDocEntry] { documents.filter { $0.collectionType == "curriculum" } }
    private var groundingDocs:  [CurriculumDocEntry] { documents.filter { $0.collectionType == "grounding"  } }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = errorMessage {
                errorView(err)
            } else if documents.isEmpty {
                emptyState
            } else {
                documentList
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Curriculum Library")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: adaptiveTopBarTrailing) {
                Button {
                    showUpload = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showUpload) {
            CurriculumUploadView(profile: profile) {
                Task { await load() }
            }
            .macSheetFrame(width: 880, height: 700)
        }
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Document List

    private var documentList: some View {
        List {
            if let err = deleteError {
                Section {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
            }

            if !curriculumDocs.isEmpty {
                Section {
                    ForEach(curriculumDocs) { doc in
                        DocRow(doc: doc)
                    }
                    .onDelete { offsets in
                        Task { await delete(from: curriculumDocs, at: offsets) }
                    }
                } header: {
                    Label("Curriculum Content (\(curriculumDocs.count))", systemImage: "book.fill")
                } footer: {
                    Text("Used by the AI lesson plan generator. Upload scope & sequence docs, unit overviews, or curriculum frameworks.")
                }
            }

            if !groundingDocs.isEmpty {
                Section {
                    ForEach(groundingDocs) { doc in
                        DocRow(doc: doc)
                    }
                    .onDelete { offsets in
                        Task { await delete(from: groundingDocs, at: offsets) }
                    }
                } header: {
                    Label("Grounding Content (\(groundingDocs.count))", systemImage: "text.page.fill")
                } footer: {
                    Text("Used by the AI companion to align explanations with what students are currently studying.")
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    // MARK: - Empty / Error

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "archivebox")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("No Documents Yet")
                .font(.title3.bold())
            Text("Tap + to upload your first curriculum document.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showUpload = true
            } label: {
                Label("Upload Document", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(message)
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
            documents = try await FirestoreService.shared.fetchCurriculumDocuments()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func delete(from list: [CurriculumDocEntry], at offsets: IndexSet) async {
        deleteError = nil
        for index in offsets {
            let doc = list[index]
            do {
                try await FirestoreService.shared.deleteCurriculumDocument(id: doc.id, collectionType: doc.collectionType)
                documents.removeAll { $0.id == doc.id }
            } catch {
                deleteError = "Failed to delete \"\(doc.title)\": \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Doc Row

private struct DocRow: View {
    let doc: CurriculumDocEntry

    private var badgeColor: Color {
        doc.collectionType == "grounding" ? .purple : .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: doc.collectionType == "grounding" ? "text.page.fill" : "book.fill")
                    .foregroundStyle(badgeColor)
                    .frame(width: 20)
                Text(doc.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
            }

            HStack(spacing: 6) {
                if !doc.gradeLevel.isEmpty {
                    chip("Grade \(doc.gradeLevel)", color: .green)
                }
                if !doc.subject.isEmpty {
                    chip(doc.subject, color: .orange)
                }
                if !doc.standard.isEmpty {
                    chip(doc.standard, color: .gray)
                }
            }

            HStack {
                Text("\(doc.wordCount) words")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if let date = doc.createdAt {
                    Text(date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
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
}

// MARK: - Upload View

struct CurriculumUploadView: View {
    let profile: UserProfile
    let onSaved: () -> Void

    private static let grades   = ["K","1","2","3","4","5","6","7","8","9","10","11","12"]
    private static let subjects = ["ELA","Math","Science","Social Studies","Art","Music","PE","Technology","Other"]

    @Environment(\.dismiss) private var dismiss

    @State private var title          = ""
    @State private var collectionType = "curriculum"
    @State private var grade          = "6"
    @State private var subject        = "Math"
    @State private var standard       = ""
    @State private var content        = ""
    @State private var isSaving       = false
    @State private var errorMessage: String?
    @State private var showFilePicker = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !content.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                documentSection
                classificationSection
                contentSection
                if let err = errorMessage {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
                saveSection
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .navigationTitle("Upload Document")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.plainText]
            ) { result in
                if case .success(let url) = result {
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let text = try? String(contentsOf: url, encoding: .utf8) {
                            content = text
                            if title.isEmpty {
                                title = url.deletingPathExtension().lastPathComponent
                                    .replacingOccurrences(of: "_", with: " ")
                                    .replacingOccurrences(of: "-", with: " ")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Form Sections

    private var documentSection: some View {
        Section {
            TextField("e.g. Grade 6 Math — Ratios Unit Overview", text: $title)
                .nameInput()

            Picker("Collection", selection: $collectionType) {
                Text("Curriculum Content").tag("curriculum")
                Text("Grounding Content").tag("grounding")
            }
        } header: {
            Text("Document")
        } footer: {
            if collectionType == "curriculum" {
                Text("Curriculum Content is used by the lesson plan generator when teachers create AI-generated plans.")
            } else {
                Text("Grounding Content is used by the AI companion to align its explanations with what students are currently studying.")
            }
        }
    }

    private var classificationSection: some View {
        Section("Classification") {
            Picker("Grade", selection: $grade) {
                ForEach(Self.grades, id: \.self) { Text("Grade \($0)").tag($0) }
            }
            Picker("Subject", selection: $subject) {
                ForEach(Self.subjects, id: \.self) { Text($0).tag($0) }
            }
            TextField("Standard (optional, e.g. 6.RP.A.1)", text: $standard)
                .nameInput()
        }
    }

    private var contentSection: some View {
        Section {
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("Paste or type curriculum text here…")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $content)
                    .frame(minHeight: 220)
                    .font(.subheadline)
            }

            HStack {
                Button {
                    showFilePicker = true
                } label: {
                    Label("Import .txt File", systemImage: "doc.badge.plus")
                        .font(.subheadline)
                }
                Spacer()
                if !content.isEmpty {
                    let words = content.split(whereSeparator: \.isWhitespace).count
                    Text("\(words) words")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Content")
        } footer: {
            Text("Paste text directly or import a plain-text (.txt) file. The AI uses the first ~4,000 characters when generating.")
        }
    }

    private var saveSection: some View {
        Section {
            Button(action: save) {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                    } else {
                        Label("Upload to Library", systemImage: "arrow.up.doc.fill")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Save

    private func save() {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        Task {
            defer { isSaving = false }
            do {
                try await FirestoreService.shared.saveCurriculumDocument(
                    title:          title.trimmingCharacters(in: .whitespaces),
                    subject:        subject,
                    gradeLevel:     grade,
                    standard:       standard.trimmingCharacters(in: .whitespaces),
                    content:        content.trimmingCharacters(in: .whitespaces),
                    collectionType: collectionType,
                    districtId:     profile.districtId,
                    uploadedBy:     profile.id
                )
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
