import SwiftUI

struct DataPrivacyView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    // FR-403: data export state
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var exportedJSON: String?
    @State private var showExportSheet = false

    // FR-404
    @State private var aiTrainingConsent: Bool = false
    @State private var isUpdatingConsent = false

    var body: some View {
        List {
            // FR-404: AI training consent toggle
            Section {
                Toggle(isOn: $aiTrainingConsent) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Help Improve EduAssist")
                            .font(.subheadline.bold())
                        Text("Allow anonymised interaction summaries to be used for AI improvement")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(isUpdatingConsent)
                .onChange(of: aiTrainingConsent) { _, newValue in
                    guard let uid = authVM.currentProfile?.id else { return }
                    isUpdatingConsent = true
                    Task {
                        try? await FirestoreService.shared.updateTrainingConsent(userId: uid, consent: newValue)
                        isUpdatingConsent = false
                    }
                }
            } footer: {
                Text("Your name, email, and school are never included. You can change this at any time.")
            }

            Section("Your Data") {
                Label("EduAssist stores your profile, learning progress, quiz results, messages, and test attempts in Firebase.", systemImage: "info.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Privacy Rights") {
                DataRightRow(icon: "eye.slash", title: "Data Access", detail: "All data is private and only accessible to you, your linked teachers, and linked parents.")
                DataRightRow(icon: "lock.shield", title: "Security", detail: "Data is encrypted in transit and at rest via Firebase's security infrastructure.")
                DataRightRow(icon: "person.badge.minus", title: "Right to Erasure", detail: "You may permanently delete your account and all associated data at any time.")
            }

            Section("Data Collected") {
                ForEach(dataTypes, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle")
                        .font(.subheadline)
                }
            }

            // FR-403: Data export — visible to parents and the student themselves
            if let profile = authVM.currentProfile,
               profile.role == .parent || profile.role == .student {
                Section {
                    if let err = exportError {
                        Text(err).foregroundStyle(.red).font(.footnote)
                    }
                    Button {
                        Task { await exportData() }
                    } label: {
                        Label(
                            isExporting ? "Preparing Export…" : "Export My Data (JSON)",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .disabled(isExporting)
                } footer: {
                    Text("Exports your full data record as a JSON file. Available immediately in compliance with COPPA's 72-hour requirement.")
                }
            }

            Section {
                if let err = deleteError {
                    Text(err).foregroundStyle(.red).font(.footnote)
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label(isDeleting ? "Deleting…" : "Delete My Account & All Data",
                          systemImage: "trash.fill")
                }
                .disabled(isDeleting)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Privacy & Data")
        .inlineNavigationTitle()
        .onAppear {
            aiTrainingConsent = authVM.currentProfile?.aiTrainingConsent ?? false
        }
        .sheet(isPresented: $showExportSheet) {
            if let json = exportedJSON {
                ExportShareSheet(json: json, studentId: authVM.currentProfile?.id ?? "export")
            }
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) { Task { await deleteAccount() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your profile, all progress, messages, and test history. This cannot be undone.")
        }
    }

    private var dataTypes: [String] {
        ["Name and email address", "Learning paths and lesson progress",
         "Quiz and test results", "Badges earned", "AI companion chat history",
         "Messages with teachers and parents", "Device push notification token"]
    }

    private func exportData() async {
        guard let profile = authVM.currentProfile else { return }
        isExporting = true
        exportError = nil
        do {
            let json = try await CloudFunctionService.shared.requestDataExport(studentId: profile.id)
            AuditService.shared.log(.dataExportRequested, userId: profile.id)
            exportedJSON = json
            showExportSheet = true
        } catch {
            exportError = "Export failed. Please try again."
        }
        isExporting = false
    }

    private func deleteAccount() async {
        guard let uid = authVM.currentProfile?.id else { return }
        isDeleting = true
        deleteError = nil
        do {
            try await FirestoreService.shared.deleteAllUserData(userId: uid)
            AuditService.shared.log(.accountDeleted, userId: uid)
            authVM.signOut()
            dismiss()
        } catch {
            deleteError = "Deletion failed. Please try again."
            isDeleting = false
        }
    }
}

// MARK: - FR-403: Share Sheet

private struct ExportShareSheet: View {
    let json: String
    let studentId: String

    private var fileURL: URL? {
        let name = "eduassist-export-\(studentId).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? json.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    var body: some View {
        if let url = fileURL {
            ShareLink(
                item: url,
                subject: Text("EduAssist Data Export"),
                message: Text("Your EduAssist data export — generated \(Date().formatted(date: .abbreviated, time: .shortened)).")
            ) {
                Label("Share Export File", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .padding()
            }
            .presentationDetents([.fraction(0.25)])
        }
    }
}

private struct DataRightRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
