import SwiftUI
import SwiftData
import FirebaseCore
// NFR-005: AppStorage keys for accessibility preferences
// (AccessibilitySettingsView owns the UI; App reads and injects them into the environment)
#if os(iOS)
import UIKit
import UserNotifications
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { @MainActor in NotificationService.shared.onTokenRefresh(token) }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
}
#endif

@main
struct EduAssistallApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    @State private var authViewModel = AuthViewModel()
    private let cacheContainer: ModelContainer

    // NFR-005: read accessibility preferences and inject into view hierarchy
    @AppStorage("a11y_dyslexiaFont")  private var dyslexiaFont:   Bool = false
    @AppStorage("a11y_highContrast")  private var highContrast:   Bool = false
    @AppStorage("a11y_largeText")     private var largeText:      Bool = false
    @AppStorage("a11y_reduceMotion")  private var reduceMotion:   Bool = false

    init() {
        FirebaseApp.configure()
        let container = try! ModelContainer(for: CachedLearningPath.self, CachedStudentProgress.self)
        cacheContainer = container
        OfflineCacheService.shared.configure(container: container)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(authViewModel)
                // NFR-005: propagate accessibility preferences to all views
                .environment(\.dyslexiaFont,    dyslexiaFont)
                .environment(\.a11yHighContrast, highContrast)
                .environment(\.a11yLargeText,    largeText)
                .environment(\.a11yReduceMotion, reduceMotion)
                .task {
                    authViewModel.startListening()
                    #if os(iOS)
                    await NotificationService.shared.requestPermission()
                    #endif
                }
                .onChange(of: authViewModel.authState) { _, newState in
                    if case .authenticated(let profile) = newState {
                        // FR-400: TLS + encryption verification
                        SecurityVerificationService.shared.verifyAndLog(userId: profile.id)
                        // FR-401: US-only data residency confirmation
                        DataResidencyService.shared.confirmAndLog(userId: profile.id)
                    }
                }
        }
    }
}
