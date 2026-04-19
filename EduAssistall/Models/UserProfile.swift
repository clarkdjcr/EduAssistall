import Foundation

enum UserRole: String, Codable, CaseIterable {
    case student
    case teacher
    case parent
    case admin
}

struct UserProfile: Codable, Identifiable {
    var id: String          // Firebase Auth UID
    var email: String
    var displayName: String
    var role: UserRole
    var onboardingComplete: Bool
    var createdAt: Date
    var fcmToken: String?
    var privacyConsentGiven: Bool
    var privacyConsentAt: Date?

    init(id: String, email: String, displayName: String, role: UserRole, privacyConsentGiven: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.onboardingComplete = false
        self.createdAt = Date()
        self.privacyConsentGiven = privacyConsentGiven
        self.privacyConsentAt = privacyConsentGiven ? Date() : nil
    }
}
