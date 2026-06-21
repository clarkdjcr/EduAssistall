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
    var aiConsentGiven: Bool
    var aiConsentAt: Date?
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

    // Phase 2: Gamification fields
    var xp: Int
    var level: Int
    var avatarConfig: AvatarConfig?
    var streakFreezes: Int
    var soundEffectsEnabled: Bool
    var hapticFeedbackEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case role
        case onboardingComplete
        case createdAt
        case fcmToken
        case privacyConsentGiven
        case privacyConsentAt
        case aiConsentGiven
        case aiConsentAt
        case districtId
        case timezone
        case birthYear
        case parentalConsentStatus
        case parentEmail
        case xp
        case level
        case avatarConfig
        case streakFreezes
        case soundEffectsEnabled
        case hapticFeedbackEnabled
    }

    // Custom decode so fields added after launch (timezone, onboardingComplete,
    // privacyConsentGiven, aiConsentGiven) don't crash older Firestore documents that lack them.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try c.decode(String.self,   forKey: .id)
        email                = try c.decode(String.self,   forKey: .email)
        displayName          = try c.decode(String.self,   forKey: .displayName)
        // Decode role case-insensitively so manually-seeded data with
        // "Teacher" or "Parent" (capital) still maps to the correct enum case.
        if let rawRole = try? c.decode(String.self, forKey: .role),
           let decoded = UserRole(rawValue: rawRole.lowercased()) {
            role = decoded
        } else {
            role = .student
        }
        onboardingComplete   = try c.decodeIfPresent(Bool.self,   forKey: .onboardingComplete)   ?? false
        createdAt            = try c.decodeIfPresent(Date.self,   forKey: .createdAt)            ?? Date()
        fcmToken             = try c.decodeIfPresent(String.self, forKey: .fcmToken)
        privacyConsentGiven  = try c.decodeIfPresent(Bool.self,   forKey: .privacyConsentGiven)  ?? false
        privacyConsentAt     = try c.decodeIfPresent(Date.self,   forKey: .privacyConsentAt)
        aiConsentGiven       = try c.decodeIfPresent(Bool.self,   forKey: .aiConsentGiven)       ?? false
        aiConsentAt          = try c.decodeIfPresent(Date.self,   forKey: .aiConsentAt)
        districtId           = try c.decodeIfPresent(String.self, forKey: .districtId)
        timezone             = try c.decodeIfPresent(String.self, forKey: .timezone) ?? TimeZone.current.identifier
        birthYear            = try c.decodeIfPresent(Int.self,    forKey: .birthYear)
        parentalConsentStatus = try c.decodeIfPresent(String.self, forKey: .parentalConsentStatus)
        parentEmail          = try c.decodeIfPresent(String.self, forKey: .parentEmail)
        xp                   = try c.decodeIfPresent(Int.self,    forKey: .xp)                   ?? 0
        level                = try c.decodeIfPresent(Int.self,    forKey: .level)                ?? 1
        avatarConfig         = try c.decodeIfPresent(AvatarConfig.self, forKey: .avatarConfig)
        streakFreezes        = try c.decodeIfPresent(Int.self,    forKey: .streakFreezes)        ?? 0
        soundEffectsEnabled  = try c.decodeIfPresent(Bool.self,   forKey: .soundEffectsEnabled)  ?? true
        hapticFeedbackEnabled = try c.decodeIfPresent(Bool.self,   forKey: .hapticFeedbackEnabled) ?? true
    }

    /// True if this student account is blocked pending a parent's email approval.
    var isPendingParentalConsent: Bool {
        parentalConsentStatus == "pending"
    }

    init(id: String, email: String, displayName: String, role: UserRole,
         privacyConsentGiven: Bool = false, aiConsentGiven: Bool = false, birthYear: Int? = nil, parentEmail: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.role = role
        self.onboardingComplete = false
        self.createdAt = Date()
        self.privacyConsentGiven = privacyConsentGiven
        self.privacyConsentAt = privacyConsentGiven ? Date() : nil
        self.aiConsentGiven = aiConsentGiven
        self.aiConsentAt = aiConsentGiven ? Date() : nil
        self.timezone = TimeZone.current.identifier
        self.birthYear = birthYear
        self.parentEmail = parentEmail
        if let year = birthYear {
            let currentYear = Calendar.current.component(.year, from: Date())
            self.parentalConsentStatus = (currentYear - year < 13) ? "pending" : "not_required"
        } else {
            self.parentalConsentStatus = (role == .student) ? nil : "not_required"
        }
        // Phase 2: Initialize gamification fields
        self.xp = 0
        self.level = 1
        self.avatarConfig = nil
        self.streakFreezes = 0
        self.soundEffectsEnabled = true
        self.hapticFeedbackEnabled = true
    }
}
