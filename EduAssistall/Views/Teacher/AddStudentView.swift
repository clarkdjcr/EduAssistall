import SwiftUI

struct AddStudentView: View {
    let teacherProfile: UserProfile

    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var email     = ""
    @State private var grade     = ""
    @State private var parentEmail = ""
    @State private var isAdding  = false
    @State private var result: AddResult?

    enum AddResult {
        case invited
        case alreadyExists
        case error(String)
    }

    private var studentName: String {
        [firstName.trimmingCharacters(in: .whitespaces),
         lastName.trimmingCharacters(in: .whitespaces)]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private var canAdd: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && email.contains("@") && !isAdding
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Student") {
                    TextField("First name", text: $firstName)
                    TextField("Last name", text: $lastName)
                    TextField("Email address ✱", text: $email)
                        .emailInput()
                    TextField("Grade (e.g. 7)", text: $grade)
                        .numberInput()
                }

                Section {
                    TextField("Parent / guardian email (optional)", text: $parentEmail)
                        .emailInput()
                } footer: {
                    Text("If provided, the parent receives an email invitation to create an account.")
                }

                if let result {
                    Section {
                        switch result {
                        case .invited:
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text("Invitation sent — student account is linked to your roster.")
                                    .font(.subheadline)
                            }
                        case .alreadyExists:
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill.checkmark").foregroundStyle(.blue)
                                Text("Student already has an account — linked to your class.")
                                    .font(.subheadline)
                            }
                        case .error(let msg):
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                Text(msg).font(.subheadline)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        Task { await addStudent() }
                    } label: {
                        HStack {
                            Spacer()
                            if isAdding {
                                ProgressView()
                            } else {
                                Text("Invite Student")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!canAdd)
                }
            }
            .navigationTitle("Invite Student")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(result != nil ? "Done" : "Cancel") { dismiss() }
                }
            }
        }
    }

    private func addStudent() async {
        isAdding = true
        result = nil
        var payload: [String: Any] = [
            "studentName": studentName,
            "studentEmail": email.trimmingCharacters(in: .whitespaces).lowercased(),
            "grade": grade.trimmingCharacters(in: .whitespaces),
        ]
        let pe = parentEmail.trimmingCharacters(in: .whitespaces).lowercased()
        if !pe.isEmpty { payload["parentEmail"] = pe }

        do {
            let r = try await CloudFunctionService.shared.bulkInviteStudents(
                students: [payload],
                teacherName: teacherProfile.displayName
            )
            if r.invited > 0 {
                result = .invited
            } else if r.alreadyExisted > 0 {
                result = .alreadyExists
            } else {
                result = .error("Could not add student. Check the email address and try again.")
            }
        } catch {
            result = .error("Something went wrong. Please try again.")
        }
        isAdding = false
    }
}
