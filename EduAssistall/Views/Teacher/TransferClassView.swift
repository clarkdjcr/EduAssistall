import SwiftUI

/// Sheet for transferring the teacher's entire active roster to another teacher.
/// Searches for the receiving teacher by email, confirms, then batch-moves all
/// confirmed student links. The current teacher's roster is cleared on success.
struct TransferClassView: View {
    let teacherProfile: UserProfile
    let activeLinks: [StudentAdultLink]
    let onTransferred: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var teacherEmail = ""
    @State private var isSearching = false
    @State private var foundTeacher: UserProfile?
    @State private var isTransferring = false
    @State private var errorMessage: String?
    @State private var transferred = false

    private var studentCount: Int { activeLinks.filter { $0.confirmed && !$0.archived }.count }

    var body: some View {
        NavigationStack {
            Form {
                // Summary
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(studentCount) student\(studentCount == 1 ? "" : "s")")
                                .font(.subheadline.bold())
                            Text("All confirmed students will move to the new teacher's roster")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Class to Transfer")
                }

                // Teacher search
                Section {
                    TextField("Receiving teacher's email", text: $teacherEmail)
                        .emailInput()
                        .autocorrectionDisabled()
                        .disabled(transferred)

                    Button {
                        Task { await searchTeacher() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSearching { ProgressView() }
                            else { Text("Find Teacher") }
                            Spacer()
                        }
                    }
                    .disabled(teacherEmail.trimmingCharacters(in: .whitespaces).isEmpty || isSearching || transferred)
                } header: {
                    Text("Transfer To")
                }

                // Found teacher + confirm
                if let teacher = foundTeacher {
                    Section("Receiving Teacher") {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill.checkmark")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(teacher.displayName)
                                    .font(.subheadline.bold())
                                Text(teacher.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button {
                            Task { await transfer(to: teacher) }
                        } label: {
                            HStack {
                                Spacer()
                                if isTransferring { ProgressView() }
                                else {
                                    Text("Transfer \(studentCount) Student\(studentCount == 1 ? "" : "s")")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(isTransferring)
                        .foregroundStyle(.blue)
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }

                if transferred {
                    Section {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("Transfer complete. \(studentCount) student\(studentCount == 1 ? "" : "s") moved to \(foundTeacher?.displayName ?? "the new teacher").")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Transfer Entire Class")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(transferred ? "Done" : "Cancel") {
                        if transferred { onTransferred() }
                        dismiss()
                    }
                }
            }
        }
    }

    private func searchTeacher() async {
        isSearching = true
        errorMessage = nil
        foundTeacher = nil
        let email = teacherEmail.trimmingCharacters(in: .whitespaces).lowercased()
        if email == teacherProfile.email.lowercased() {
            errorMessage = "That's your own account. Enter a different teacher's email."
            isSearching = false
            return
        }
        do {
            foundTeacher = try await FirestoreService.shared.fetchTeacherByEmail(email)
            if foundTeacher == nil { errorMessage = "No teacher account found with that email." }
        } catch {
            errorMessage = "Could not search for teacher. Please try again."
        }
        isSearching = false
    }

    private func transfer(to newTeacher: UserProfile) async {
        isTransferring = true
        errorMessage = nil
        do {
            try await FirestoreService.shared.transferClass(links: activeLinks, newTeacherId: newTeacher.id)
            transferred = true
        } catch {
            errorMessage = "Transfer failed. Please try again."
        }
        isTransferring = false
    }
}
