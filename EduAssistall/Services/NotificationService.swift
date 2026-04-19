import Foundation
#if os(iOS)
import UIKit
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

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

    func onTokenRefresh(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            try? await FirestoreService.shared.saveFCMToken(userId: uid, token: token)
        }
        AuditService.shared.log(.fcmTokenRefreshed, userId: uid)
    }
}
#endif
