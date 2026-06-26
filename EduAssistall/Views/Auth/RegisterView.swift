import SwiftUI

struct RegisterView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Binding var showRegister: Bool

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var consentGiven = false
    @State private var isLoading = false
    @State private var errorMessage: String?

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
                        Text("Parents can create accounts here. Students join through a teacher invitation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)

                    // Open registration is parent-only. Student accounts are created
                    // through teacher invitations, and teachers are provisioned by
                    // school or district administrators.
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account type")
                            .font(.headline)
                            .padding(.horizontal, 24)

                        RoleCard(role: .parent, isSelected: true) {}
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Students need a teacher invitation before signing in.", systemImage: "envelope.badge")
                            Label("Teachers and school staff need administrator provisioning.", systemImage: "person.badge.shield.checkmark")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .newPasswordInput()
                                .padding()
                                .background(Color.appSecondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            if !confirmPassword.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.caption2)
                                    Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                        .font(.caption2)
                                }
                                .foregroundStyle(password == confirmPassword ? Color.green : Color.red)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.2), value: password == confirmPassword)
                            }
                        }

                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.25), value: errorMessage)
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
        return true
    }

    private func register() async {
        guard formIsValid else {
            if password != confirmPassword {
                errorMessage = "Passwords do not match."
            } else if password.count < 6 {
                errorMessage = "Password must be at least 6 characters."
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
                role: .parent,
                privacyConsentGiven: consentGiven
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
