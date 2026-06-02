import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AuthError: Error {
    case missingClientID
    case missingToken
}

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case pendingParentalConsent(UserProfile)   // COPPA: under-13 student awaiting parent email approval
    case onboarding(UserProfile)
    case authenticated(UserProfile)
}

@Observable
final class AuthViewModel {
    var authState: AuthState = .loading
    private var stateListener: AuthStateDidChangeListenerHandle?

    init() {
        // Do not touch Firebase here — FirebaseApp.configure() may not have
        // run yet. Call startListening() after the app entry point finishes init.
    }

    /// Must be called once, after FirebaseApp.configure() has run.
    func startListening() {
        guard stateListener == nil else { return }
        listenToAuthState()
    }

    deinit {
        if let handle = stateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func listenToAuthState() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                await self?.handleAuthStateChange(user: user)
            }
        }
    }

    @MainActor
    private func handleAuthStateChange(user: FirebaseAuth.User?) async {
        guard let user else {
            NSLog("[Auth] state → unauthenticated (no user)")
            authState = .unauthenticated
            return
        }
        NSLog("[Auth] state change for uid=%@ providers=%@", user.uid, user.providerData.map { $0.providerID }.joined(separator: ","))
        do {
            NSLog("[Auth] fetching Firestore profile…")
            if let profile = try await FirestoreService.shared.fetchUserProfile(uid: user.uid) {
                NSLog("[Auth] profile found onboardingComplete=%d pendingConsent=%d", profile.onboardingComplete, profile.isPendingParentalConsent)
                if profile.isPendingParentalConsent {
                    authState = .pendingParentalConsent(profile)
                } else if profile.onboardingComplete {
                    authState = .authenticated(profile)
                } else {
                    authState = .onboarding(profile)
                }
                Task { try? await FirestoreService.shared.updateTimezone(uid: user.uid) }
            } else {
                NSLog("[Auth] no profile found, creating one…")
                let providerIDs = user.providerData.map { $0.providerID }
                let consentGiven = providerIDs.contains("microsoft.com") || providerIDs.contains("google.com")
                let profile = UserProfile(
                    id: user.uid,
                    email: (user.email ?? "").lowercased(),
                    displayName: user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User",
                    role: .student,
                    privacyConsentGiven: consentGiven
                )
                try await FirestoreService.shared.saveUserProfile(profile)
                NSLog("[Auth] profile saved → onboarding")
                authState = .onboarding(profile)
            }
        } catch {
            NSLog("[Auth] ERROR loading profile: %@", "\(error)")
            // Only sign out for auth/permission failures. A network blip or
            // decode error should not strand users on the login screen.
            let nsError = error as NSError
            let isAuthError = nsError.domain == "FIRAuthErrorDomain"
            let isPermissionError = nsError.domain == "FIRFirestoreErrorDomain" && nsError.code == 7
            if isAuthError || isPermissionError {
                try? Auth.auth().signOut()
                authState = .unauthenticated
            } else {
                // Network / decode failure — keep the user in loading state
                // so they aren't bounced back to the login screen. The listener
                // will re-fire if the auth token refreshes.
                NSLog("[Auth] non-fatal error, staying in current state")
            }
        }
    }

    /// Re-fetches the Firestore profile and updates auth state.
    /// Used by PendingParentalConsentView to check if a parent has approved.
    func reloadProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let profile = try? await FirestoreService.shared.fetchUserProfile(uid: uid) else { return }
        if profile.isPendingParentalConsent {
            authState = .pendingParentalConsent(profile)
        } else if profile.onboardingComplete {
            authState = .authenticated(profile)
        } else {
            authState = .onboarding(profile)
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String, role: UserRole,
                privacyConsentGiven: Bool = false, birthYear: Int? = nil, parentEmail: String? = nil) async throws {
        let normalizedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        let result = try await Auth.auth().createUser(withEmail: normalizedEmail, password: password)
        let profile = UserProfile(
            id: result.user.uid,
            email: normalizedEmail,
            displayName: displayName,
            role: role,
            privacyConsentGiven: privacyConsentGiven,
            birthYear: birthYear,
            parentEmail: parentEmail
        )
        try await FirestoreService.shared.saveUserProfile(profile)
        AuditService.shared.log(.signUp, userId: result.user.uid)

        // COPPA: if this student is under 13, send the parental consent email.
        // Account is created but stays in .pendingParentalConsent state until the parent approves.
        if profile.isPendingParentalConsent, let parentEmail {
            try? await CloudFunctionService.shared.sendParentalConsentEmail(
                studentId: result.user.uid,
                parentEmail: parentEmail
            )
        }
    }

    // MARK: - Google Sign-In
    // Requires GoogleSignIn-iOS SPM package: https://github.com/google/GoogleSignIn-iOS
    // Add URL scheme (REVERSED_CLIENT_ID from GoogleService-Info.plist) to Info.plist
    #if canImport(GoogleSignIn)
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                       accessToken: result.user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credential)
        // Create profile if first sign-in
        if (try? await FirestoreService.shared.fetchUserProfile(uid: authResult.user.uid)) == nil {
            let profile = UserProfile(
                id: authResult.user.uid,
                email: authResult.user.email ?? "",
                displayName: authResult.user.displayName ?? "User",
                role: .student,
                privacyConsentGiven: true
            )
            try await FirestoreService.shared.saveUserProfile(profile)
        }
        AuditService.shared.log(.signIn, userId: authResult.user.uid, metadata: ["provider": "google"])
    }
    func requestClassroomScopes(presenting viewController: UIViewController) async throws -> String {
        let scopes = [
            "https://www.googleapis.com/auth/classroom.courses.readonly",
            "https://www.googleapis.com/auth/classroom.rosters.readonly"
        ]
        let result = try await GIDSignIn.sharedInstance.addScopes(scopes, presenting: viewController)
        guard let token = result?.user.accessToken.tokenString else {
            throw AuthError.missingToken
        }
        return token
    }
    #endif

    // MARK: - Microsoft / Entra Sign-In

    #if os(iOS)
    func signInWithMicrosoft() async throws {
        let provider = OAuthProvider(providerID: "microsoft.com")
        provider.scopes = ["email", "profile", "openid"]
        provider.customParameters = [
            "prompt": "select_account",
            "tenant": "bfc0bf6c-e85e-46a1-b8ce-f43da0b421c5"
        ]

        // nil delegate → Firebase uses ASWebAuthenticationSession, which avoids
        // the iOS 16.4+ SFSafariViewController storage-partitioning error.
        let credential: AuthCredential = try await withCheckedThrowingContinuation { continuation in
            provider.getCredentialWith(nil) { credential, error in
                if let error { continuation.resume(throwing: error) }
                else if let credential { continuation.resume(returning: credential) }
                else { continuation.resume(throwing: AuthError.missingToken) }
            }
        }

        let authResult = try await Auth.auth().signIn(with: credential)
        AuditService.shared.log(.signIn, userId: authResult.user.uid, metadata: ["provider": "microsoft"])
    }
    #endif

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        AuditService.shared.log(.signIn, userId: result.user.uid)
    }

    // MARK: - Sign Out

    @MainActor
    func signOut() {
        if let uid = Auth.auth().currentUser?.uid {
            AuditService.shared.log(.signOut, userId: uid)
            OfflineCacheService.shared.clearAll(for: uid)
        }
        // Call Firebase signOut() directly — do NOT mutate authState here.
        // signOut() fires the auth state listener synchronously, but the listener
        // wraps handleAuthStateChange in Task { @MainActor in ... }, so the view-
        // hierarchy transition is *enqueued* and runs after the current event
        // completes. This lets open sheets finish their presentation cycle before
        // the hierarchy is replaced (fixing a freeze/crash when signing out from
        // a Learning sheet), while still avoiding the DispatchQueue.main.async
        // deferral that previously raced with iPadOS 26's TabView layout pass.
        try? Auth.auth().signOut()
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await FirestoreService.shared.updateOnboardingComplete(uid: uid)
        // Reload profile
        if let profile = try await FirestoreService.shared.fetchUserProfile(uid: uid) {
            authState = .authenticated(profile)
        }
    }

    func updateAIConsent(granted: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await FirestoreService.shared.updateAIConsent(uid: uid, granted: granted)
        await reloadProfile()
    }

    // MARK: - Helpers

    var currentProfile: UserProfile? {
        switch authState {
        case .onboarding(let p), .authenticated(let p), .pendingParentalConsent(let p): return p
        default: return nil
        }
    }
}

