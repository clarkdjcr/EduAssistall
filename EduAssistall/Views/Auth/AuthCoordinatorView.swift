import SwiftUI

struct AuthCoordinatorView: View {
    @State private var showRegister = false
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        if !hasSeenWelcome {
            WelcomeView {
                hasSeenWelcome = true
            }
        } else if showRegister {
            RegisterView(showRegister: $showRegister)
        } else {
            LoginView(showRegister: $showRegister)
        }
    }
}
