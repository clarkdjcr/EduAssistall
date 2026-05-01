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
    /// IANA timezone identifier (e.g. "America/Los_Angeles"). Auto-detected from the
    /// device on first sign-in and refreshed on every subsequent sign-in so the digest
    /// always fires at 6 AM local time regardless of where the teacher is located.
    var timezone: String

    // COPPA: present only for student accounts. nil = not required (adult or non-student).
    var birthYear: Int?
    // "not_required" | "pending" | "approved" — nil treated as "not_required" for existing documents.
    var parentalConsentStatus: String?
    var parentEmail: String?

    /// True if this student account is blocked pending a parent's email approval.
    var isPendingParentalConsent: Bool {
        parentalConsentStatus == "pending"
    }

    init(id: String, email: String, displayName: String, role: UserRole,
         privacyConsentGiven: Bool = false, birthYear: Int? = nil, parentEmail: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.onboardingComplete = false
        self.createdAt = Date()
        self.privacyConsentGiven = privacyConsentGiven
        self.privacyConsentAt = privacyConsentGiven ? Date() : nil
        self.timezone = TimeZone.current.identifier
        self.birthYear = birthYear
        self.parentEmail = parentEmail
        if let year = birthYear {
            let currentYear = Calendar.current.component(.year, from: Date())
            self.parentalConsentStatus = (currentYear - year < 13) ? "pending" : "not_required"
        } else {
            self.parentalConsentStatus = (role == .student) ? nil : "not_required"
        }
    }
}
