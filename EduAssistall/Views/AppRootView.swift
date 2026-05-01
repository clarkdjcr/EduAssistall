import SwiftUI

struct AppRootView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
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
