import Foundation

enum UserRole: String, Codable, CaseIterable {
    case student
    case teacher
    case parent
    case admin
}

struct UserProfile: Codable, Identifiable, Equatable {
    var id: String          // Firebase Auth UID
    var email: String
    var displayName: String
    var role: UserRole
    var onboardingComplete: Bool
    var createdAt: Date
    var fcmToken: String?
    var privacyConsentGiven: Bool
    var privacyConsentAt: Date?
    var districtId: String?
    var aiTrainingConsent: Bool       // FR-404: explicit opt-in required; default false
    var aiTrainingConsentAt: Date?
    /// IANA timezone identifier (e.g. "America/Los_Angeles"). Auto-detected from the
    /// device on first sign-in and refreshed on every subsequent sign-in so the digest
    /// always fires at 6 AM local time regardless of where the teacher is located.
    var timezone: String

    init(id: String, email: String, displayName: String, role: UserRole, privacyConsentGiven: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.onboardingComplete = false
        self.createdAt = Date()
        self.privacyConsentGiven = privacyConsentGiven
        self.privacyConsentAt = privacyConsentGiven ? Date() : nil
        self.aiTrainingConsent = false
        self.aiTrainingConsentAt = nil
        self.timezone = TimeZone.current.identifier
    }
}
