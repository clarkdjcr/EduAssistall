import Foundation
import FirebaseCore
import FirebaseFunctions

// MARK: - CompanionError

/// Typed errors returned by askCompanion. All raw Firebase/network errors are
/// translated here so views never need to inspect FunctionsErrorCode directly.
enum CompanionError: LocalizedError {
    /// Per-user hourly call limit reached (server rate limit).
    case rateLimited
    /// Educator has paused this student's companion session (kill switch).
    case sessionLocked
    /// Claude API is temporarily down or overloaded.
    case aiUnavailable
    /// Claude API call timed out.
    case aiTimeout
    /// Device has no network connectivity.
    case offline
    /// Any other unexpected failure.
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "You've reached your message limit for this hour. You can send more messages after the hour resets."
        case .sessionLocked:
            return "Your companion session has been paused by your educator. Please speak with them to continue."
        case .aiUnavailable:
            return "The AI is temporarily unavailable. Please try again in a moment."
        case .aiTimeout:
            return "The AI took too long to respond. Please try again."
        case .offline:
            return "You appear to be offline. Please check your connection and try again."
        case .unknown(let detail):
            return detail.isEmpty ? "Something went wrong. Please try again." : detail
        }
    }

    /// True for transient errors the user can immediately retry.
    var isRetryable: Bool {
        switch self {
        case .aiUnavailable, .aiTimeout, .offline, .unknown: return true
        case .rateLimited, .sessionLocked: return false
        }
    }
}

// MARK: - Catalog Item (returned by curateContent Cloud Function)

struct CatalogItem: Identifiable {
    let externalId: String
    let title: String
    let description: String
    let contentType: String       // "video" | "article"
    let url: String
    let source: String            // "khanacademy" | "edx"
    let subject: String
    let estimatedMinutes: Int

    var id: String { externalId }

    init?(from dict: [String: Any], defaultSubject: String) {
        guard let externalId = dict["externalId"] as? String,
              let title = dict["title"] as? String,
              let url = dict["url"] as? String,
              !url.isEmpty, url != "https://www.khanacademy.org" else { return nil }
        self.externalId = externalId
        self.title = title
        self.description = dict["description"] as? String ?? ""
        self.contentType = dict["contentType"] as? String ?? "video"
        self.url = url
        self.source = dict["source"] as? String ?? "khanacademy"
        self.subject = dict["subject"] as? String ?? defaultSubject
        self.estimatedMinutes = dict["estimatedMinutes"] as? Int ?? 8
    }

    func toContentItem(teacherId: String, gradeLevel: String) -> ContentItem {
        var item = ContentItem(
            title: title,
            description: description,
            contentType: contentType == "video" ? .video : .article,
            url: url,
            subject: subject,
            gradeLevel: gradeLevel,
            estimatedMinutes: estimatedMinutes,
            createdBy: teacherId
        )
        item.source = source
        item.externalId = externalId
        return item
    }
}

// MARK: - Book Suggestion (returned by suggestLessonMaterials Cloud Function)

struct BookSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let rationale: String
}

// MARK: - Service

final class CloudFunctionService {
    static let shared = CloudFunctionService()
    private lazy var functions = Functions.functions(region: "us-central1")

    private init() {}

    // MARK: - Teacher AI Document Generation

    struct LessonPlanResult {
        let lessonPlan: String
        let documentId: String?
        let recommendationId: String?
    }

    struct LessonDayRecommendation: Identifiable {
        let id: String
        let dayNumber: Int
        let title: String
        let rationale: String
        var lessonPlanText: String
    }

    struct LessonPlanAssignmentResult {
        let contentItemId: String
        let learningPathIds: [String]
        let assignedCount: Int
    }

    struct ParentLetterResult {
        let letter: String
        let documentId: String?
        let studentName: String
    }

    func generateLessonPlan(
        grade: String,
        subject: String,
        topic: String,
        durationMinutes: Int = 45,
        standard: String = "",
        startDate: Date? = nil,
        endDate: Date? = nil,
        teachingDays: [String] = [],
        supplementalResources: String = "",
        teacherNotes: String = "",
        teacherWikiDigest: String = ""
    ) async throws -> LessonPlanResult {
        var data: [String: Any] = [
            "grade": grade,
            "subject": subject,
            "topic": topic,
            "durationMinutes": durationMinutes,
        ]
        if !standard.isEmpty { data["standard"] = standard }
        if let startDate { data["startDate"] = Self.lessonDateFormatter.string(from: startDate) }
        if let endDate { data["endDate"] = Self.lessonDateFormatter.string(from: endDate) }
        if !teachingDays.isEmpty { data["teachingDays"] = teachingDays }
        if !supplementalResources.isEmpty { data["supplementalResources"] = supplementalResources }
        if !teacherNotes.isEmpty { data["teacherNotes"] = teacherNotes }
        if !teacherWikiDigest.isEmpty { data["teacherWikiDigest"] = teacherWikiDigest }
        let result = try await functions.httpsCallable("generateLessonPlan").call(data)
        guard let dict = result.data as? [String: Any],
              let plan = dict["lessonPlan"] as? String else {
            throw URLError(.badServerResponse)
        }
        return LessonPlanResult(
            lessonPlan: plan,
            documentId: dict["documentId"] as? String,
            recommendationId: dict["recommendationId"] as? String
        )
    }

    func approveLessonPlanAndGenerateDays(
        recommendationId: String?,
        title: String,
        grade: String,
        subject: String,
        standard: String,
        lessonPlan: String,
        startDate: Date?,
        endDate: Date?,
        teachingDays: [String]
    ) async throws -> [LessonDayRecommendation] {
        var data: [String: Any] = [
            "title": title,
            "grade": grade,
            "subject": subject,
            "standard": standard,
            "lessonPlan": lessonPlan,
            "teachingDays": teachingDays,
        ]
        if let recommendationId { data["recommendationId"] = recommendationId }
        if let startDate { data["startDate"] = Self.lessonDateFormatter.string(from: startDate) }
        if let endDate { data["endDate"] = Self.lessonDateFormatter.string(from: endDate) }
        let result = try await functions.httpsCallable("approveLessonPlanAndGenerateDays").call(data)
        guard let dict = result.data as? [String: Any],
              let rawDays = dict["days"] as? [[String: Any]] else {
            throw URLError(.badServerResponse)
        }
        return rawDays.compactMap { raw in
            guard let id = raw["id"] as? String,
                  let title = raw["title"] as? String,
                  let lessonPlanText = raw["lessonPlanText"] as? String else { return nil }
            return LessonDayRecommendation(
                id: id,
                dayNumber: raw["dayNumber"] as? Int ?? 0,
                title: title,
                rationale: raw["rationale"] as? String ?? "",
                lessonPlanText: lessonPlanText
            )
        }
    }

    func assignLessonPlan(
        title: String,
        description: String,
        grade: String,
        subject: String,
        standard: String,
        lessonPlan: String,
        documentId: String?,
        dailyPlans: [LessonDayRecommendation] = [],
        studentIds: [String],
        weekOf: Date = Date()
    ) async throws -> LessonPlanAssignmentResult {
        var data: [String: Any] = [
            "title": title,
            "description": description,
            "grade": grade,
            "subject": subject,
            "standard": standard,
            "lessonPlan": lessonPlan,
            "studentIds": studentIds,
            "weekOf": Self.lessonDateFormatter.string(from: weekOf),
        ]
        if let documentId { data["documentId"] = documentId }
        if !dailyPlans.isEmpty {
            data["dailyPlans"] = dailyPlans.map { day in
                [
                    "recommendationId": day.id,
                    "dayNumber": day.dayNumber,
                    "title": day.title,
                    "rationale": day.rationale,
                    "lessonPlanText": day.lessonPlanText,
                ] as [String: Any]
            }
        }
        let result = try await functions.httpsCallable("assignLessonPlan").call(data)
        guard let dict = result.data as? [String: Any],
              dict["ok"] as? Bool == true else {
            throw URLError(.badServerResponse)
        }
        return LessonPlanAssignmentResult(
            contentItemId: dict["contentItemId"] as? String ?? "",
            learningPathIds: dict["learningPathIds"] as? [String] ?? [],
            assignedCount: dict["assignedCount"] as? Int ?? 0
        )
    }

    private static let lessonDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func generateParentLetter(
        studentId: String,
        letterType: String,
        subject: String = "",
        teacherNotes: String = ""
    ) async throws -> ParentLetterResult {
        var data: [String: Any] = [
            "studentId": studentId,
            "letterType": letterType,
        ]
        if !subject.isEmpty      { data["subject"] = subject }
        if !teacherNotes.isEmpty { data["teacherNotes"] = teacherNotes }
        let result = try await functions.httpsCallable("generateParentLetter").call(data)
        guard let dict = result.data as? [String: Any],
              let letter = dict["letter"] as? String else {
            throw URLError(.badServerResponse)
        }
        return ParentLetterResult(
            letter: letter,
            documentId: dict["documentId"] as? String,
            studentName: dict["studentName"] as? String ?? "Student"
        )
    }

    // MARK: - AI Usage Statistics (FR-G5)

    struct AIUsageStats {
        struct Period {
            let calls: Int
            let inputTokens: Int
            let outputTokens: Int
            let groundingHits: Int
            let estimatedCostUSD: Double
        }
        struct LatencyStats {
            let p50ms: Int?
            let p95ms: Int?
            let p99ms: Int?
            let breachingTarget: Bool
        }
        let today: Period
        let month: Period
        let byFeature: [String: Int]
        let latency: LatencyStats
        let generatedAt: String
    }

    func getAIUsageStats() async throws -> AIUsageStats {
        let result = try await functions.httpsCallable("getAIUsageStats").call([:])
        guard let dict = result.data as? [String: Any] else { throw URLError(.badServerResponse) }

        func parsePeriod(_ key: String) -> AIUsageStats.Period {
            let p = dict[key] as? [String: Any] ?? [:]
            return AIUsageStats.Period(
                calls:            p["calls"]            as? Int    ?? 0,
                inputTokens:      p["inputTokens"]      as? Int    ?? 0,
                outputTokens:     p["outputTokens"]     as? Int    ?? 0,
                groundingHits:    p["groundingHits"]    as? Int    ?? 0,
                estimatedCostUSD: p["estimatedCostUSD"] as? Double ?? 0
            )
        }

        let lat = dict["latency"] as? [String: Any] ?? [:]
        return AIUsageStats(
            today:       parsePeriod("today"),
            month:       parsePeriod("month"),
            byFeature:   dict["byFeature"] as? [String: Int] ?? [:],
            latency: AIUsageStats.LatencyStats(
                p50ms:          lat["p50ms"] as? Int,
                p95ms:          lat["p95ms"] as? Int,
                p99ms:          lat["p99ms"] as? Int,
                breachingTarget: lat["breachingTarget"] as? Bool ?? false
            ),
            generatedAt: dict["generatedAt"] as? String ?? ""
        )
    }

    func generateRecommendations(studentId: String) async throws {
        let data: [String: Any] = ["studentId": studentId]
        _ = try await functions.httpsCallable("generateRecommendations").call(data)
    }

    func curateContent(subject: String, gradeLevel: String, source: String = "khanacademy") async throws -> [CatalogItem] {
        let data: [String: Any] = ["subject": subject, "gradeLevel": gradeLevel, "source": source]
        let result = try await functions.httpsCallable("curateContent").call(data)
        guard let dict = result.data as? [String: Any],
              let rawItems = dict["items"] as? [[String: Any]] else { return [] }
        return rawItems.compactMap { CatalogItem(from: $0, defaultSubject: subject) }
    }

    /// ELA-only: asks the AI for 2-3 grade-appropriate book/text options for a lesson topic,
    /// so the teacher can pick one (or supply their own) before the lesson plan is generated.
    func suggestLessonMaterials(grade: String, topic: String, standard: String) async throws -> [BookSuggestion] {
        var data: [String: Any] = ["grade": grade, "subject": "ELA", "topic": topic]
        if !standard.isEmpty { data["standard"] = standard }
        let result = try await functions.httpsCallable("suggestLessonMaterials").call(data)
        guard let dict = result.data as? [String: Any],
              let rawItems = dict["suggestions"] as? [[String: Any]] else { return [] }
        return rawItems.compactMap { item in
            guard let title = item["title"] as? String, !title.isEmpty else { return nil }
            return BookSuggestion(
                title: title,
                author: item["author"] as? String ?? "",
                rationale: item["rationale"] as? String ?? ""
            )
        }
    }

    func bulkInviteStudents(students: [[String: Any]], teacherName: String) async throws -> ImportResult {
        let data: [String: Any] = ["students": students, "teacherName": teacherName]
        let result = try await functions.httpsCallable("bulkInviteStudents").call(data)
        guard let dict = result.data as? [String: Any] else { throw URLError(.badServerResponse) }
        return ImportResult(
            invited: dict["invited"] as? Int ?? 0,
            alreadyExisted: dict["alreadyExisted"] as? Int ?? 0,
            errorCount: (dict["errors"] as? [[String: Any]])?.count ?? 0
        )
    }

    /// Looks up a student by email server-side. Only callable by users with role == "parent".
    /// Returns (studentId, displayName) — never the full UserProfile.
    func lookupStudentByEmail(_ email: String) async throws -> (studentId: String, displayName: String) {
        let result = try await functions.httpsCallable("lookupStudentByEmail").call(["email": email])
        guard let dict = result.data as? [String: Any],
              let studentId = dict["studentId"] as? String,
              let displayName = dict["displayName"] as? String else {
            throw URLError(.badServerResponse)
        }
        return (studentId, displayName)
    }

    func importClassroomRoster(googleAccessToken: String, teacherId: String) async throws -> Int {
        let data: [String: Any] = ["googleAccessToken": googleAccessToken, "teacherId": teacherId]
        let result = try await functions.httpsCallable("importClassroomRoster").call(data)
        return (result.data as? [String: Any])?["imported"] as? Int ?? 0
    }

    /// FR-002: Record a learning milestone so the companion can reference it cross-session.
    func recordMilestone(studentId: String, type: MilestoneType, title: String, subject: String) async throws {
        let data: [String: Any] = [
            "studentId": studentId,
            "type": type.rawValue,
            "title": title,
            "subject": subject,
        ]
        _ = try? await functions.httpsCallable("recordMilestone").call(data)
    }

    /// FR-403: Request a full data export for a student. Returns pretty-printed JSON string.
    func requestDataExport(studentId: String) async throws -> String {
        let result = try await functions.httpsCallable("requestDataExport").call(["studentId": studentId])
        guard let dict = result.data as? [String: Any],
              let exportObj = dict["export"] else {
            throw URLError(.badServerResponse)
        }
        let data = try JSONSerialization.data(withJSONObject: exportObj, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// FR-302: Ask the server to generate a learning journal entry for the just-completed session.
    /// Fire-and-forget — caller should not await or handle errors.
    func generateJournalEntry(studentId: String, conversationId: String) {
        Task {
            _ = try? await functions.httpsCallable("generateJournalEntry").call([
                "studentId": studentId,
                "conversationId": conversationId,
            ])
        }
    }

    func saveJournalReflection(
        studentId: String,
        entryId: String,
        reflection: String,
        shareWithTeacher: Bool,
        shareWithParent: Bool
    ) async throws -> (reflection: String, safetyStatus: String, safetyReason: String?) {
        let result = try await functions.httpsCallable("saveJournalReflection").call([
            "studentId": studentId,
            "entryId": entryId,
            "reflection": reflection,
            "shareWithTeacher": shareWithTeacher,
            "shareWithParent": shareWithParent,
        ])
        guard let dict = result.data as? [String: Any],
              dict["success"] as? Bool == true else {
            throw URLError(.badServerResponse)
        }
        return (
            reflection: dict["reflection"] as? String ?? reflection,
            safetyStatus: dict["safetyStatus"] as? String ?? "safe",
            safetyReason: dict["safetyReason"] as? String
        )
    }

    func askCompanion(
        message: String,
        studentId: String,
        mode: InteractionMode = .guidedDiscovery,
        compressedHistory: String? = nil,
        currentSubject: String? = nil
    ) async throws -> String {
        var data: [String: Any] = [
            "message": message,
            "studentId": studentId,
            "conversationId": studentId,
            "interactionMode": mode.rawValue,
        ]
        if let compressed = compressedHistory { data["compressedHistory"] = compressed }
        if let subject = currentSubject, !subject.isEmpty { data["currentSubject"] = subject }
        do {
            let result = try await functions.httpsCallable("askCompanion").call(data)
            guard let dict = result.data as? [String: Any],
                  let reply = dict["reply"] as? String else {
                throw CompanionError.unknown("")
            }
            return reply
        } catch let error as NSError {
            throw companionError(from: error)
        }
    }

    /// COPPA: sends a parental consent email for an under-13 student.
    /// Called immediately after account creation; failure is non-fatal (account still created).
    func sendParentalConsentEmail(studentId: String, parentEmail: String) async throws {
        _ = try await functions.httpsCallable("sendParentalConsentEmail").call([
            "studentId": studentId,
            "parentEmail": parentEmail,
        ])
    }

    // MARK: - IT Admin Setup Verification

    struct SetupVerificationResult {
        struct SecretsStatus {
            let anthropicKey: Bool
            let sendgridKey: Bool
            let azureTenantId: Bool
            let azureClientId: Bool
            let azureClientSecret: Bool
            let sharepointSiteId: Bool
            let curriculumListId: Bool
            let officialDocsListId: Bool
            let studentContentListId: Bool
            let policiesListId: Bool
            let districtApiKeyConfigured: Bool

            /// True when at least one Anthropic key is usable (district key preferred).
            var coreAIReady: Bool { districtApiKeyConfigured || anthropicKey }
            var emailReady: Bool { sendgridKey }
            var azureCredsReady: Bool { azureTenantId && azureClientId && azureClientSecret }
            var sharepointCoreReady: Bool { sharepointSiteId }
        }
        struct ListsStatus {
            let curriculum: Bool
            let officialDocs: Bool
            let studentContent: Bool
            let policies: Bool
        }
        let secrets: SecretsStatus
        let azureConnected: Bool
        let azureError: String?
        let sharePointSiteAccessible: Bool
        let sharePointError: String?
        let lists: ListsStatus
        let discoveredLists: [DiscoveredList]
        let checkedAt: String

        var overallHealthy: Bool {
            secrets.coreAIReady && azureConnected && sharePointSiteAccessible
        }
    }

    struct DiscoveredList: Identifiable {
        let id: String
        let name: String
    }

    struct WebhookRegistrationResult {
        let listId: String
        let status: String
        let subscriptionId: String?
        let error: String?
        var succeeded: Bool { status == "registered" }
    }

    func verifySharePointSetup() async throws -> SetupVerificationResult {
        let result = try await functions.httpsCallable("verifySharePointSetup").call([:])
        guard let dict = result.data as? [String: Any] else { throw URLError(.badServerResponse) }
        let s = dict["secretsConfigured"] as? [String: Bool] ?? [:]
        let l = dict["sharePointLists"] as? [String: Bool] ?? [:]
        return SetupVerificationResult(
            secrets: SetupVerificationResult.SecretsStatus(
                anthropicKey:             s["ANTHROPIC_API_KEY"]                ?? false,
                sendgridKey:              s["SENDGRID_API_KEY"]                 ?? false,
                azureTenantId:            s["AZURE_TENANT_ID"]                  ?? false,
                azureClientId:            s["AZURE_CLIENT_ID"]                  ?? false,
                azureClientSecret:        s["AZURE_CLIENT_SECRET"]              ?? false,
                sharepointSiteId:         s["SHAREPOINT_SITE_ID"]               ?? false,
                curriculumListId:         s["SHAREPOINT_CURRICULUM_LIST_ID"]    ?? false,
                officialDocsListId:       s["SHAREPOINT_OFFICIAL_DOCS_LIST_ID"] ?? false,
                studentContentListId:     s["SHAREPOINT_STUDENT_CONTENT_LIST_ID"] ?? false,
                policiesListId:           s["SHAREPOINT_POLICIES_LIST_ID"]      ?? false,
                districtApiKeyConfigured: dict["districtApiKeyConfigured"]       as? Bool ?? false
            ),
            azureConnected:          dict["azureConnected"]             as? Bool   ?? false,
            azureError:              dict["azureError"]                 as? String,
            sharePointSiteAccessible:dict["sharePointSiteAccessible"]   as? Bool   ?? false,
            sharePointError:         dict["sharePointError"]            as? String,
            lists: SetupVerificationResult.ListsStatus(
                curriculum:   l["curriculum"]    ?? false,
                officialDocs: l["officialDocs"]  ?? false,
                studentContent: l["studentContent"] ?? false,
                policies:     l["policies"]      ?? false
            ),
            discoveredLists: (dict["discoveredLists"] as? [[String: String]] ?? []).compactMap { d in
                guard let id = d["id"], let name = d["name"] else { return nil }
                return DiscoveredList(id: id, name: name)
            },
            checkedAt: dict["checkedAt"] as? String ?? ""
        )
    }

    struct ListCreationResult: Identifiable {
        var id: String { name }
        let name: String
        let listId: String?
        let status: String   // "created" | "existed" | "failed"
        let error: String?
        var succeeded: Bool { status == "created" || status == "existed" }
    }

    func createSharePointLists() async throws -> [ListCreationResult] {
        let result = try await functions.httpsCallable("createSharePointLists").call([:])
        guard let dict = result.data as? [String: Any],
              let raw = dict["results"] as? [[String: Any]] else {
            throw URLError(.badServerResponse)
        }
        return raw.map { r in
            ListCreationResult(
                name:   r["name"]   as? String ?? "",
                listId: r["id"]     as? String,
                status: r["status"] as? String ?? "",
                error:  r["error"]  as? String
            )
        }
    }

    func registerSharePointWebhooks() async throws -> [WebhookRegistrationResult] {
        let projectId = FirebaseApp.app()?.options.projectID ?? "eduassist-b1f49"
        let url = "https://us-central1-\(projectId).cloudfunctions.net/sharepointWebhookReceiver"
        let result = try await functions.httpsCallable("registerSharePointWebhooks").call(["webhookUrl": url])
        guard let dict = result.data as? [String: Any],
              let rawResults = dict["results"] as? [[String: Any]] else {
            throw URLError(.badServerResponse)
        }
        return rawResults.map { r in
            WebhookRegistrationResult(
                listId:         r["listId"]         as? String ?? "",
                status:         r["status"]         as? String ?? "",
                subscriptionId: r["subscriptionId"] as? String,
                error:          r["error"]          as? String
            )
        }
    }

    func approveDocument(documentId: String, action: String) async throws {
        let result = try await functions.httpsCallable("approveDocument").call([
            "documentId": documentId,
            "action": action,
        ])
        guard let dict = result.data as? [String: Any],
              dict["success"] as? Bool == true else {
            throw URLError(.badServerResponse)
        }
    }

    func approveStandardsUpdate(alertId: String, decision: String, notes: String = "") async throws {
        let result = try await functions.httpsCallable("approveStandardsUpdate").call([
            "alertId": alertId,
            "decision": decision,
            "notes": notes,
        ])
        guard let dict = result.data as? [String: Any],
              dict["ok"] as? Bool == true else {
            throw URLError(.badServerResponse)
        }
    }

    func setDocumentBackend(_ backend: String) async throws {
        let result = try await functions.httpsCallable("setDocumentBackend").call(["backend": backend])
        guard let dict = result.data as? [String: Any],
              dict["success"] as? Bool == true else {
            throw URLError(.badServerResponse)
        }
    }

    func setDistrictApiKey(_ apiKey: String) async throws {
        let result = try await functions.httpsCallable("setDistrictApiKey").call(["apiKey": apiKey])
        guard let dict = result.data as? [String: Any],
              dict["success"] as? Bool == true else {
            throw URLError(.badServerResponse)
        }
    }

    /// Translates any NSError from the Firebase Functions SDK into a typed CompanionError.
    private func companionError(from error: NSError) -> CompanionError {
        // Already a CompanionError (e.g. from the guard above) — pass through.
        if let ce = error as? CompanionError { return ce }

        // Network unreachable — check before Firebase codes so URLError is caught too.
        if error.domain == NSURLErrorDomain {
            let code = URLError.Code(rawValue: error.code)
            if [.notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost].contains(code) {
                return .offline
            }
            return .aiUnavailable
        }

        // Firebase Functions errors carry the gRPC status code in the error code field.
        guard error.domain == FunctionsErrorDomain else {
            return .unknown("")
        }

        switch FunctionsErrorCode(rawValue: error.code) {
        case .resourceExhausted:  return .rateLimited
        case .permissionDenied:   return .sessionLocked
        case .unavailable:        return .aiUnavailable
        case .deadlineExceeded:   return .aiTimeout
        case .unauthenticated:
            // Surface the server message directly — it says "Must be signed in."
            return .unknown(error.localizedDescription)
        default:
            return .unknown("")
        }
    }
}
