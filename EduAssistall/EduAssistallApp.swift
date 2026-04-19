import SwiftUI
import FirebaseCore

@main
struct EduAssistallApp: App {
    @State private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authViewModel)
                .task {
                    authViewModel.startListening()
                    #if os(iOS)
                    await NotificationService.shared.requestPermission()
                    #endif
                }
        }
    }
}
