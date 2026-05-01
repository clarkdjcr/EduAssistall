import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Binding var showRegister: Bool

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .student
    @State private var consentGiven = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    // COPPA: age gate for student accounts
    private static let currentYear = Calendar.current.component(.year, from: Date())
    @State private var birthYear: Int = currentYear - 14   // default to 14-year-old
    @State private var parentEmail = ""

    private var isUnder13: Bool {
        selectedRole == .student && (Self.currentYear - birthYear) < 13
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text("Create Account")
                            .font(.title.bold())
                        Text("Join EduAssist today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    // Role Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I am a...")
                            .font(.headline)
                            .padding(.horizontal, 24)

                        HStack(spacing: 12) {
                            ForEach([UserRole.student, .teacher, .parent], id: \.self) { role in
                                RoleCard(role: role, isSelected: selectedRole == role) {
                                    selectedRole = role
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Form Fields
                    VStack(spacing: 14) {
                        TextField("Full Name", text: $displayName)
                            .nameInput()
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        TextField("Email", text: $email)
                            .emailInput()
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .newPasswordInput()
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Confirm Password", text: $confirmPassword)
                            .newPasswordInput()
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if selectedRole == .student {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Year of Birth")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Picker("Year of Birth", selection: $birthYear) {
                                    ForEach((Self.currentYear - 18)...(Self.currentYear - 4), id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                                .clipped()
                                .background(Color.appSecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            if isUnder13 {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("Parental consent required for students under 13", systemImage: "info.circle")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    TextField("Parent or Guardian Email", text: $parentEmail)
                                        .emailInput()
                                        .padding()
                                        .background(Color.appSecondaryBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    Text("We'll send your parent a one-time approval email. Your account will be active once they approve.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Toggle(isOn: $consentGiven) {
                            Text("I agree to the collection and use of my data as described in the Privacy Policy.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .toggleStyle(.automatic)

                        Button {
                            Task { await register() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isLoading || !formIsValid || !consentGiven)
                    }
                    .padding(.horizontal, 24)

                    // Sign in link
                    Button {
                        showRegister = false
                    } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign in")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var formIsValid: Bool {
        guard !displayName.isEmpty && !email.isEmpty &&
              password.count >= 6 && password == confirmPassword && consentGiven else { return false }
        if isUnder13 {
            return parentEmail.contains("@") && !parentEmail.isEmpty
        }
        return true
    }

    private func register() async {
        guard formIsValid else {
            if password != confirmPassword {
                errorMessage = "Passwords do not match."
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters."
            } else if isUnder13 && !parentEmail.contains("@") {
                errorMessage = "Please enter a valid parent or guardian email."
            }
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await authVM.signUp(
                email: email,
                password: password,
                displayName: displayName,
                role: selectedRole,
                privacyConsentGiven: consentGiven,
                birthYear: selectedRole == .student ? birthYear : nil,
                parentEmail: isUnder13 ? parentEmail : nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Role Card

private struct RoleCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void

    var title: String {
        switch role {
        case .student: return "Student"
        case .teacher: return "Teacher"
        case .parent: return "Parent /\nGuardian"
        case .admin: return "Admin"
        }
    }

    var subtitle: String {
        switch role {
        case .student: return "I am here to learn"
        case .teacher: return "I manage a classroom"
        case .parent: return "I oversee my child's progress"
        case .admin: return "District admin"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .blue.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.appSecondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
