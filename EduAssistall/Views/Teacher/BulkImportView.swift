import SwiftUI
import UniformTypeIdentifiers

struct BulkImportView: View {
    let teacherProfile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @State private var step: ImportStep = .pick
    @State private var csv: ParsedCSV?
    @State private var columnMap = ColumnMap()
    @State private var records: [StudentImportRecord] = []
    @State private var isImporting = false
    @State private var result: ImportResult?
    @State private var showFilePicker = false
    @State private var parseError: String?

    enum ImportStep { case pick, map, preview, done }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .pick:    pickStep
                case .map:     mapStep
                case .preview: previewStep
                case .done:    doneStep
                }
            }
            .navigationTitle(stepTitle)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker,
                      allowedContentTypes: [.commaSeparatedText, .plainText],
                      allowsMultipleSelection: false) { result in
            handleFilePick(result)
        }
    }

    private var stepTitle: String {
        switch step {
        case .pick:    return "Import Roster"
        case .map:     return "Map Columns"
        case .preview: return "Preview"
        case .done:    return "Import Complete"
        }
    }

    // MARK: - Step 1: Pick File

    private var pickStep: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: "doc.text.below.ecg")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.opacity(0.7))
                    .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Import from Spreadsheet")
                        .font(.title2.bold())
                    Text("Upload a CSV file exported from Excel, Google Sheets, or your school's student information system.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Expected format card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Expected columns")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(expectedColumns, id: \.self) { col in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Text(col)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                if let error = parseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Choose CSV File", systemImage: "folder")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Text("To export from Excel: File → Save As → CSV (Comma delimited)\nFrom Google Sheets: File → Download → CSV")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(Color.appGroupedBackground)
    }

    private let expectedColumns = [
        "First Name (or Student Name)",
        "Last Name",
        "Student Email",
        "Grade",
        "Parent/Guardian Email (optional)",
        "Parent/Guardian Name (optional)"
    ]

    // MARK: - Step 2: Map Columns

    private var mapStep: some View {
        List {
            Section {
                Text("We detected \(csv?.headers.count ?? 0) columns. Confirm the mapping below or tap a column to change it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            Section("Required") {
                ColumnPickerRow(label: "Student First Name", icon: "person",
                                selectedIndex: $columnMap.studentFirstName, headers: csv?.headers ?? [])
                ColumnPickerRow(label: "Student Last Name", icon: "person",
                                selectedIndex: $columnMap.studentLastName, headers: csv?.headers ?? [])
                ColumnPickerRow(label: "Student Email ✱", icon: "envelope",
                                selectedIndex: $columnMap.studentEmail, headers: csv?.headers ?? [])
                ColumnPickerRow(label: "Grade", icon: "graduationcap",
                                selectedIndex: $columnMap.grade, headers: csv?.headers ?? [])
            }

            Section("Optional — Parent / Guardian") {
                ColumnPickerRow(label: "Parent Email", icon: "envelope.badge",
                                selectedIndex: $columnMap.parentEmail, headers: csv?.headers ?? [])
                ColumnPickerRow(label: "Parent First Name", icon: "figure.2.and.child.holdinghands",
                                selectedIndex: $columnMap.parentFirstName, headers: csv?.headers ?? [])
                ColumnPickerRow(label: "Parent Last Name", icon: "figure.2.and.child.holdinghands",
                                selectedIndex: $columnMap.parentLastName, headers: csv?.headers ?? [])
            }

            Section {
                Button {
                    buildRecords()
                    step = .preview
                } label: {
                    Text("Preview Import")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(columnMap.studentEmail == nil)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
    }

    // MARK: - Step 3: Preview

    private var previewStep: some View {
        List {
            let valid   = records.filter(\.isValid)
            let invalid = records.filter { !$0.isValid }

            Section {
                HStack(spacing: 20) {
                    Label("\(valid.count) ready", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    if !invalid.isEmpty {
                        Label("\(invalid.count) skipped", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.subheadline.bold())
                .listRowBackground(Color.clear)
            }

            if !invalid.isEmpty {
                Section("Rows with errors (will be skipped)") {
                    ForEach(invalid) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.studentEmail.isEmpty ? "(no email)" : record.studentEmail)
                                    .font(.subheadline)
                                Text(record.validationError ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            Section("Students to import (first 10 shown)") {
                ForEach(valid.prefix(10)) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.studentName)
                            .font(.subheadline.bold())
                        Text(record.studentEmail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            if !record.grade.isEmpty {
                                Label("Grade \(record.grade)", systemImage: "graduationcap")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if !record.parentEmail.isEmpty {
                                Label("Parent linked", systemImage: "figure.2.and.child.holdinghands")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                if valid.count > 10 {
                    Text("… and \(valid.count - 10) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    Task { await runImport(records: valid) }
                } label: {
                    HStack {
                        Spacer()
                        if isImporting {
                            ProgressView()
                        } else {
                            Text("Send \(valid.count) Invitation\(valid.count == 1 ? "" : "s")")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(valid.isEmpty || isImporting)
            } footer: {
                Text("Each new student receives an email invitation with a secure sign-in link. Students who already have an account are linked immediately.")
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
    }

    // MARK: - Step 4: Done

    private var doneStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: result?.errorCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(result?.errorCount == 0 ? Color.green : Color.orange)

            VStack(spacing: 8) {
                Text("Import Complete")
                    .font(.title2.bold())
                if let r = result {
                    Text("\(r.invited) invitation\(r.invited == 1 ? "" : "s") sent")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if r.alreadyExisted > 0 {
                        Text("\(r.alreadyExisted) student\(r.alreadyExisted == 1 ? "" : "s") already had accounts — linked automatically")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    if r.errorCount > 0 {
                        Text("\(r.errorCount) row\(r.errorCount == 1 ? "" : "s") could not be imported")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .background(Color.appGroupedBackground)
    }

    // MARK: - Logic

    private func handleFilePick(_ result: Result<[URL], Error>) {
        parseError = nil
        switch result {
        case .failure(let err):
            parseError = err.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                parseError = "Permission denied to read file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let parsed = CSVParser.parse(content)
                guard !parsed.headers.isEmpty else {
                    parseError = "The file appears to be empty or is not a valid CSV."
                    return
                }
                csv = parsed
                columnMap = CSVParser.autoDetectColumns(headers: parsed.headers)
                step = .map
            } catch {
                // Try latin-1 as fallback for files saved by older Excel versions
                if let content = try? String(contentsOf: url, encoding: .isoLatin1) {
                    let parsed = CSVParser.parse(content)
                    csv = parsed
                    columnMap = CSVParser.autoDetectColumns(headers: parsed.headers)
                    step = .map
                } else {
                    parseError = "Could not read the file. Make sure it is saved as CSV (not .xlsx)."
                }
            }
        }
    }

    private func buildRecords() {
        guard let csv else { return }
        records = csv.rows.map { row in
            let email = columnMap.studentEmail.map { $0 < row.count ? row[$0] : "" } ?? ""
            let grade = columnMap.grade.map { $0 < row.count ? row[$0] : "" } ?? ""
            let parentEmail = columnMap.parentEmail.map { $0 < row.count ? row[$0] : "" } ?? ""
            return StudentImportRecord(
                studentName: columnMap.studentName(from: row),
                studentEmail: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                grade: grade,
                parentEmail: parentEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                parentName: columnMap.parentName(from: row)
            )
        }
    }

    private func runImport(records: [StudentImportRecord]) async {
        isImporting = true
        let students = records.map { r -> [String: Any] in
            var dict: [String: Any] = [
                "studentName": r.studentName,
                "studentEmail": r.studentEmail,
                "grade": r.grade,
            ]
            if !r.parentEmail.isEmpty { dict["parentEmail"] = r.parentEmail }
            if !r.parentName.isEmpty  { dict["parentName"]  = r.parentName  }
            return dict
        }
        do {
            let r = try await CloudFunctionService.shared.bulkInviteStudents(
                students: students,
                teacherName: teacherProfile.displayName
            )
            result = r
            step = .done
        } catch {
            result = ImportResult(invited: 0, alreadyExisted: 0, errorCount: records.count)
            step = .done
        }
        isImporting = false
    }
}

// MARK: - Column Picker Row

private struct ColumnPickerRow: View {
    let label: String
    let icon: String
    @Binding var selectedIndex: Int?
    let headers: [String]

    private var noneTag: Int? { nil }

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
            Spacer()
            Picker("", selection: Binding(
                get: { selectedIndex ?? -1 },
                set: { selectedIndex = $0 == -1 ? nil : $0 }
            )) {
                Text("— not mapped —").tag(-1)
                ForEach(Array(headers.enumerated()), id: \.offset) { i, h in
                    Text(h).tag(i)
                }
            }
            .labelsHidden()
            .frame(maxWidth: 160)
        }
    }
}

// MARK: - Import Result

struct ImportResult {
    let invited: Int
    let alreadyExisted: Int
    let errorCount: Int
}
