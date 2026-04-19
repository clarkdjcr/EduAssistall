import Foundation
#if os(iOS)
import UIKit
import FirebaseAuth
import UserNotifications

// FCM token registration requires the FirebaseMessaging package.
// Add it later via: File → Add Package Dependencies → firebase-ios-sdk → FirebaseMessaging
// For now this service requests system notification permission only.

@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()

    private override init() { super.init() }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted {
            await UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
#endif
