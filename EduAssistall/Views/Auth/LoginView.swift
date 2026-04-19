import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Binding var showRegister: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo / Header
                    VStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.blue)
                        Text("EduAssist")
                            .font(.largeTitle.bold())
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 48)

                    // Form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .emailInput()
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .passwordInput()
                            .padding()
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let error = errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            Task { await signIn() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                    }
                    .padding(.horizontal, 24)

                    // Divider
                    HStack {
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                        Text("or").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 8)
                        Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.horizontal, 24)

                    // Google Sign-In (requires GoogleSignIn-iOS SPM package)
                    #if canImport(GoogleSignIn)
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
                    .padding(.horizontal, 24)
                    #endif

                    // Create account link
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
            }
        }
    }

    private func signIn() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await authVM.signIn(email: email, password: password)
        } catch {
            errorMessage = "Sign in failed. Please check your credentials."
        }
        isLoading = false
    }
}
