import SwiftUI

struct AppRootView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--screenshots") {
            ScreenshotModeView()
        } else if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            uitestingContent
        } else {
            authContent
        }
        #else
        authContent
        #endif
    }

    /// Bypasses Firebase and injects a mock profile based on the --uitesting-role-teacher
    /// launch arg (defaults to student). Used only in XCUITest runs.
    private var uitestingContent: some View {
        let args  = ProcessInfo.processInfo.arguments
        let role: UserRole = args.contains("--uitesting-role-teacher") ? .teacher : .student
        var profile = UserProfile(
            id: role == .teacher ? "uitest-teacher-uid" : "uitest-student-uid",
            email: role == .teacher ? "uitest.teacher@eduassist.test" : "uitest.student@eduassist.test",
            displayName: role == .teacher ? "Test Teacher" : "Test Student",
            role: role,
            privacyConsentGiven: true,
            aiConsentGiven: true
        )
        profile.onboardingComplete = true
        return MainTabView(profile: profile)
    }

    @ViewBuilder
    private var authContent: some View {
        switch authVM.authState {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)

        case .unauthenticated:
            AuthCoordinatorView()

        case .pendingParentalConsent(let profile):
            PendingParentalConsentView(profile: profile)

        case .onboarding(let profile):
            OnboardingCoordinatorView(profile: profile)

        case .authenticated(let profile):
            MainTabView(profile: profile)
        }
    }
}
