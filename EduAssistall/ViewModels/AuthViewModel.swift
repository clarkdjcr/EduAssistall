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
            Task {
                await self?.handleAuthStateChange(user: user)
            }
        }
    }

    private func handleAuthStateChange(user: FirebaseAuth.User?) async {
        guard let user else {
            authState = .unauthenticated
            return
        }
        do {
            if let profile = try await FirestoreService.shared.fetchUserProfile(uid: user.uid) {
                authState = profile.onboardingComplete ? .authenticated(profile) : .onboarding(profile)
                // Refresh timezone on every sign-in — fire-and-forget, never blocks navigation.
                Task { try? await FirestoreService.shared.updateTimezone(uid: user.uid) }
            } else {
                // User exists in Auth but has no Firestore profile (edge case — treat as unauthenticated)
                try? Auth.auth().signOut()
                authState = .unauthenticated
            }
        } catch {
            authState = .unauthenticated
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, displayName: String, role: UserRole, privacyConsentGiven: Bool = false) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let profile = UserProfile(
            id: result.user.uid,
            email: email,
            displayName: displayName,
            role: role,
            privacyConsentGiven: privacyConsentGiven
        )
        try await FirestoreService.shared.saveUserProfile(profile)
        AuditService.shared.log(.signUp, userId: result.user.uid)
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

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        AuditService.shared.log(.signIn, userId: result.user.uid)
    }

    // MARK: - Sign Out

    func signOut() {
        if let uid = Auth.auth().currentUser?.uid {
            AuditService.shared.log(.signOut, userId: uid)
            OfflineCacheService.shared.clearAll(for: uid)
        }
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

    // MARK: - Helpers

    var currentProfile: UserProfile? {
        switch authState {
        case .onboarding(let p), .authenticated(let p): return p
        default: return nil
        }
    }
}
