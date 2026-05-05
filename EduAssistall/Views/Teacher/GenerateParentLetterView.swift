import SwiftUI

struct GenerateParentLetterView: View {
    let teacherProfile: UserProfile

    private static let subjects = ["","ELA","Math","Science","Social Studies","Art","Music","PE","Technology","Other"]

    private static let letterTypes: [(value: String, label: String, icon: String)] = [
        ("progress",     "Progress Update",       "chart.line.uptrend.xyaxis"),
        ("concern",      "Academic Concern",       "exclamationmark.triangle"),
        ("intervention", "Intervention Notice",    "person.badge.plus"),
        ("invitation",   "Event Invitation",       "calendar.badge.plus"),
        ("general",      "General Communication",  "envelope"),
    ]

    @State private var linkedStudents: [(id: String, name: String)] = []
    @State private var selectedStudentId = ""
    @State private var letterType        = "progress"
    @State private var subject           = ""
    @State private var teacherNotes      = ""
    @State private var isLoading         = true
    @State private var isGenerating      = false
    @State private var result: CloudFunctionService.ParentLetterResult?
    @State private var errorMessage: String?
    @State private var showResult        = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading students…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if linkedStudents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No Linked Students")
                            .font(.title3.bold())
                        Text("Link students to your roster before generating letters.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Form {
                        Section("Student") {
                            Picker("Student", selection: $selectedStudentId) {
                                ForEach(linkedStudents, id: \.id) {
                                    Text($0.name).tag($0.id)
                                }
                            }
                        }

                        Section("Letter Type") {
                            ForEach(Self.letterTypes, id: \.value) { type in
                                HStack {
                                    Label(type.label, systemImage: type.icon)
                                    Spacer()
                                    if letterType == type.value {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { letterType = type.value }
                            }
                        }

                        Section("Optional Details") {
                            Picker("Subject", selection: $subject) {
                                Text("Any").tag("")
                                ForEach(Self.subjects.dropFirst(), id: \.self) { Text($0).tag($0) }
                            }
                            TextField("Teacher notes (not sent to parent)", text: $teacherNotes, axis: .vertical)
                                .lineLimit(3...6)
                        }

                        if let msg = errorMessage {
                            Section {
                                Text(msg)
                                    .foregroundStyle(.red)
                                    .font(.subheadline)
                            }
                        }

                        Section {
                            Button(action: generate) {
                                if isGenerating {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(.white)
                                        Text("Generating…")
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    Label("Generate Letter", systemImage: "sparkles")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedStudentId.isEmpty || isGenerating)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
            }
            .navigationTitle("Parent Letter")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showResult) {
                if let result {
                    DocumentResultView(
                        title: "Parent Letter — \(result.studentName)",
                        body: result.letter,
                        sharepointItemId: result.sharepointItemId,
                        documentType: "parent letter"
                    )
                }
            }
        }
        .task { await loadStudents() }
    }

    private func loadStudents() async {
        isLoading = true
        let links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id))?.filter(\.confirmed) ?? []
        var students: [(String, String)] = []
        for link in links {
            let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId))?.displayName ?? "Student"
            students.append((link.studentId, name))
        }
        linkedStudents = students
        selectedStudentId = students.first?.id ?? ""
        isLoading = false
    }

    private func generate() {
        errorMessage = nil
        isGenerating = true
        Task {
            defer { isGenerating = false }
            do {
                result = try await CloudFunctionService.shared.generateParentLetter(
                    studentId: selectedStudentId,
                    letterType: letterType,
                    subject: subject,
                    teacherNotes: teacherNotes.trimmingCharacters(in: .whitespaces)
                )
                showResult = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
