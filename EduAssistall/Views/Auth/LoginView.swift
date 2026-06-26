import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Binding var showRegister: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var appeared = false

    // Forgot password
    @State private var showForgotPassword = false
    @State private var resetEmail = ""
    @State private var resetSent = false
    @State private var resetError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    heroSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -18)
                        .animation(.easeOut(duration: 0.45), value: appeared)

                    formSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.45).delay(0.12), value: appeared)

                    footerSection
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.45).delay(0.22), value: appeared)
                }
                .padding(.bottom, 48)
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email address", text: $resetEmail)
                .emailInput()
            Button("Send Reset Link") {
                Task { await sendReset() }
            }
            Button("Cancel", role: .cancel) {
                resetError = nil
            }
        } message: {
            if let err = resetError {
                Text(err)
            } else if resetSent {
                Text("Check your inbox for a reset link.")
            } else {
                Text("We'll email you a link to reset your password.")
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.18), Color.indigo.opacity(0.06)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 48)

            Text("EduAssist")
                .font(.largeTitle.bold())

            Text("Sign in to continue")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $email)
                .emailInput()
                .padding()
                .background(Color.appSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("login_email_field")

            VStack(alignment: .trailing, spacing: 6) {
                SecureField("Password", text: $password)
                    .passwordInput()
                    .padding()
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("login_password_field")
                    .onSubmit { Task { await signIn() } }

                Button("Forgot password?") {
                    resetEmail = email
                    resetSent = false
                    resetError = nil
                    showForgotPassword = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
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

            Button {
                Task { await signIn() }
            } label: {
                Group {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .accessibilityIdentifier("login_sign_in_button")

            // Google Sign-In (requires GoogleSignIn-iOS SPM package)
            #if canImport(GoogleSignIn)
            HStack {
                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                Text("or").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 8)
                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
            }

            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                Task {
                    #if os(iOS)
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let vc = windowScene.windows.first?.rootViewController else { return }
                    try? await authVM.signInWithGoogle(presenting: vc)
                    #endif
                }
            }
            .frame(height: 44)
            #endif
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Footer

    private var footerSection: some View {
        Button {
            showRegister = true
        } label: {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)
                Text("Sign up")
                    .foregroundStyle(.blue)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Actions

    private func signIn() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authVM.signIn(email: email, password: password)
        } catch {
            withAnimation { errorMessage = authErrorMessage(error) }
        }
        isLoading = false
    }

    private func sendReset() async {
        let target = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else {
            resetError = "Please enter your email address."
            return
        }
        do {
            try await authVM.resetPassword(email: target)
            resetSent = true
            resetError = nil
        } catch {
            resetError = "Couldn't send reset email. Check the address and try again."
        }
    }

    private func authErrorMessage(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case 17004, 17009: return "Incorrect email or password."
        case 17011:        return "No account found for that email."
        case 17010:        return "Too many attempts. Try again later."
        default:           return "Sign in failed. Please try again."
        }
    }
}
