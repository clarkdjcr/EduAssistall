import SwiftUI

struct DataPrivacyView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    var body: some View {
        List {
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
