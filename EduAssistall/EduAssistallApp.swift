import SwiftUI
import FirebaseCore
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
