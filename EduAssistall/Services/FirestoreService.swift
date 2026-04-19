import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - UserProfile

    func saveUserProfile(_ profile: UserProfile) async throws {
        let data = try Firestore.Encoder().encode(profile)
        try await db.collection("users").document(profile.id).setData(data)
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: UserProfile.self)
    }

    func updateOnboardingComplete(uid: String) async throws {
        try await db.collection("users").document(uid).updateData([
            "onboardingComplete": true
        ])
    }

    // MARK: - LearningProfile

    func saveLearningProfile(_ profile: LearningProfile) async throws {
        let data = try Firestore.Encoder().encode(profile)
        try await db.collection("learningProfiles").document(profile.studentId).setData(data)
    }

    func fetchLearningProfile(studentId: String) async throws -> LearningProfile? {
        let snapshot = try await db.collection("learningProfiles").document(studentId).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: LearningProfile.self)
    }

    // MARK: - StudentAdultLink

    func createStudentAdultLink(_ link: StudentAdultLink) async throws {
        let data = try Firestore.Encoder().encode(link)
        try await db.collection("studentAdultLinks").document(link.id).setData(data)
    }

    func fetchLinkedStudents(adultId: String) async throws -> [StudentAdultLink] {
        let snapshot = try await db.collection("studentAdultLinks")
            .whereField("adultId", isEqualTo: adultId)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: StudentAdultLink.self) }
    }

    func findStudentByEmail(_ email: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .whereField("role", isEqualTo: UserRole.student.rawValue)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first.map { try $0.data(as: UserProfile.self) }
    }

    // MARK: - ContentItems

    func saveContentItem(_ item: ContentItem) async throws {
        let data = try Firestore.Encoder().encode(item)
        try await db.collection("contentItems").document(item.id).setData(data)
    }

    func fetchContentItem(id: String) async throws -> ContentItem? {
        let snapshot = try await db.collection("contentItems").document(id).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: ContentItem.self)
    }

    func fetchContentItems(ids: [String]) async throws -> [ContentItem] {
        guard !ids.isEmpty else { return [] }
        // Firestore whereField in: supports up to 30 items
        let chunks = stride(from: 0, to: ids.count, by: 30).map {
            Array(ids[$0..<min($0 + 30, ids.count)])
        }
        var results: [ContentItem] = []
        for chunk in chunks {
            let snapshot = try await db.collection("contentItems")
                .whereField("id", in: chunk)
                .getDocuments()
            results += try snapshot.documents.map { try $0.data(as: ContentItem.self) }
        }
        return results
    }

    // MARK: - LearningPaths

    func saveLearningPath(_ path: LearningPath) async throws {
        let data = try Firestore.Encoder().encode(path)
        try await db.collection("learningPaths").document(path.id).setData(data)
    }

    func fetchLearningPaths(studentId: String) async throws -> [LearningPath] {
        let snapshot = try await db.collection("learningPaths")
            .whereField("studentId", isEqualTo: studentId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: LearningPath.self) }
    }

    func fetchAllLearningPaths(studentId: String) async throws -> [LearningPath] {
        let snapshot = try await db.collection("learningPaths")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: LearningPath.self) }
    }

    func fetchLearningPathsCreatedBy(teacherId: String) async throws -> [LearningPath] {
        let snapshot = try await db.collection("learningPaths")
            .whereField("createdBy", isEqualTo: teacherId)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: LearningPath.self) }
    }

    func deleteLearningPath(id: String) async throws {
        try await db.collection("learningPaths").document(id).delete()
    }

    // MARK: - StudentProgress

    func saveProgress(_ progress: StudentProgress) async throws {
        let data = try Firestore.Encoder().encode(progress)
        try await db.collection("studentProgress").document(progress.id).setData(data)
    }

    func fetchProgress(studentId: String, contentItemId: String) async throws -> StudentProgress? {
        let id = "\(studentId)_\(contentItemId)"
        let snapshot = try await db.collection("studentProgress").document(id).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: StudentProgress.self)
    }

    func fetchAllProgress(studentId: String) async throws -> [StudentProgress] {
        let snapshot = try await db.collection("studentProgress")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: StudentProgress.self) }
    }

    // MARK: - Recommendations

    func saveRecommendation(_ rec: Recommendation) async throws {
        let data = try Firestore.Encoder().encode(rec)
        try await db.collection("recommendations").document(rec.id).setData(data)
    }

    func fetchPendingRecommendations(studentIds: [String]) async throws -> [Recommendation] {
        guard !studentIds.isEmpty else { return [] }
        let chunks = stride(from: 0, to: studentIds.count, by: 10).map {
            Array(studentIds[$0..<min($0 + 10, studentIds.count)])
        }
        var results: [Recommendation] = []
        for chunk in chunks {
            let snapshot = try await db.collection("recommendations")
                .whereField("studentId", in: chunk)
                .whereField("status", isEqualTo: RecommendationStatus.pending.rawValue)
                .getDocuments()
            results += try snapshot.documents.map { try $0.data(as: Recommendation.self) }
        }
        return results.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchRecommendations(studentId: String) async throws -> [Recommendation] {
        let snapshot = try await db.collection("recommendations")
            .whereField("studentId", isEqualTo: studentId)
            .whereField("status", isEqualTo: RecommendationStatus.approved.rawValue)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Recommendation.self) }
    }

    func updateRecommendationStatus(id: String, status: RecommendationStatus, reviewedBy: String) async throws {
        try await db.collection("recommendations").document(id).updateData([
            "status": status.rawValue,
            "reviewedBy": reviewedBy,
            "reviewedAt": Date()
        ])
    }

    // MARK: - Quiz Questions

    func saveQuizQuestion(_ question: QuizQuestion) async throws {
        let data = try Firestore.Encoder().encode(question)
        try await db.collection("quizQuestions").document(question.id).setData(data)
    }

    func fetchQuizQuestions(contentItemId: String) async throws -> [QuizQuestion] {
        let snapshot = try await db.collection("quizQuestions")
            .whereField("contentItemId", isEqualTo: contentItemId)
            .getDocuments()
        return try snapshot.documents
            .map { try $0.data(as: QuizQuestion.self) }
            .sorted { $0.order < $1.order }
    }

    func deleteQuizQuestion(id: String) async throws {
        try await db.collection("quizQuestions").document(id).delete()
    }

    func saveQuizAttempt(_ attempt: QuizAttempt) async throws {
        let data = try Firestore.Encoder().encode(attempt)
        try await db.collection("quizAttempts").document(attempt.id).setData(data)
    }

    // MARK: - Badges

    func fetchBadges(studentId: String) async throws -> [Badge] {
        let snapshot = try await db.collection("studentBadges")
            .document(studentId)
            .collection("earned")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Badge.self) }
    }

    func awardBadge(studentId: String, type: BadgeType) async throws {
        let badge = Badge(id: type.rawValue, badgeType: type, earnedAt: Date())
        let data = try Firestore.Encoder().encode(badge)
        try await db.collection("studentBadges")
            .document(studentId)
            .collection("earned")
            .document(type.rawValue)
            .setData(data, merge: false)
    }

    // MARK: - Test Attempts

    func saveTestAttempt(_ attempt: TestAttempt) async throws {
        let data = try Firestore.Encoder().encode(attempt)
        try await db.collection("testAttempts").document(attempt.id).setData(data)
    }

    func fetchTestAttempts(studentId: String) async throws -> [TestAttempt] {
        let snapshot = try await db.collection("testAttempts")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()
        return try snapshot.documents
            .map { try $0.data(as: TestAttempt.self) }
            .sorted { $0.completedAt > $1.completedAt }
    }

    // MARK: - Messaging

    func fetchMessageThreads(userId: String) async throws -> [MessageThread] {
        let snapshot = try await db.collection("messageThreads")
            .whereField("participants", arrayContains: userId)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: MessageThread.self) }
    }

    func createMessageThread(_ thread: MessageThread) async throws {
        let data = try Firestore.Encoder().encode(thread)
        try await db.collection("messageThreads").document(thread.id).setData(data)
    }

    func fetchMessages(threadId: String) async throws -> [Message] {
        let snapshot = try await db.collection("messageThreads")
            .document(threadId)
            .collection("messages")
            .order(by: "createdAt")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Message.self) }
    }

    func sendMessage(_ message: Message) async throws {
        let data = try Firestore.Encoder().encode(message)
        try await db.collection("messageThreads")
            .document(message.threadId)
            .collection("messages")
            .document(message.id)
            .setData(data)
        // Update thread summary
        try await db.collection("messageThreads").document(message.threadId).updateData([
            "lastMessage": message.body,
            "lastMessageAt": message.createdAt
        ])
    }

    func fetchLinkedAdults(studentId: String) async throws -> [StudentAdultLink] {
        let snapshot = try await db.collection("studentAdultLinks")
            .whereField("studentId", isEqualTo: studentId)
            .whereField("confirmed", isEqualTo: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: StudentAdultLink.self) }
    }

    // MARK: - Push Notifications

    func saveFCMToken(userId: String, token: String) async throws {
        try await db.collection("users").document(userId).updateData(["fcmToken": token])
    }

    // MARK: - Account Deletion (COPPA Right to Erasure)

    func deleteAllUserData(userId: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection("users").document(userId))
        batch.deleteDocument(db.collection("learningProfiles").document(userId))

        let progressSnap = try await db.collection("studentProgress").whereField("studentId", isEqualTo: userId).getDocuments()
        progressSnap.documents.forEach { batch.deleteDocument($0.reference) }

        let attemptsSnap = try await db.collection("testAttempts").whereField("studentId", isEqualTo: userId).getDocuments()
        attemptsSnap.documents.forEach { batch.deleteDocument($0.reference) }

        let quizSnap = try await db.collection("quizAttempts").whereField("studentId", isEqualTo: userId).getDocuments()
        quizSnap.documents.forEach { batch.deleteDocument($0.reference) }

        let badgesSnap = try await db.collection("studentBadges").document(userId).collection("earned").getDocuments()
        badgesSnap.documents.forEach { batch.deleteDocument($0.reference) }

        let recsSnap = try await db.collection("recommendations").whereField("studentId", isEqualTo: userId).getDocuments()
        recsSnap.documents.forEach { batch.deleteDocument($0.reference) }

        let pathsSnap = try await db.collection("learningPaths").whereField("studentId", isEqualTo: userId).getDocuments()
        pathsSnap.documents.forEach { batch.deleteDocument($0.reference) }

        try await batch.commit()
    }

    // MARK: - Badges

    func checkAndAwardBadges(studentId: String) async {
        do {
            let existingBadges = (try? await fetchBadges(studentId: studentId)) ?? []
            let earnedTypes = Set(existingBadges.map(\.badgeType))

            let allProgress = (try? await fetchAllProgress(studentId: studentId)) ?? []
            let completed = allProgress.filter { $0.status == .completed }

            // First lesson
            if !earnedTypes.contains(.firstLesson) && !completed.isEmpty {
                try await awardBadge(studentId: studentId, type: .firstLesson)
            }

            // All subjects (3+ distinct subjects)
            if !earnedTypes.contains(.allSubjects) {
                let completedIds = completed.map(\.contentItemId)
                if !completedIds.isEmpty {
                    let items = (try? await fetchContentItems(ids: completedIds)) ?? []
                    let subjects = Set(items.map(\.subject).filter { !$0.isEmpty })
                    if subjects.count >= 3 {
                        try await awardBadge(studentId: studentId, type: .allSubjects)
                    }
                }
            }

            // Path complete
            if !earnedTypes.contains(.pathComplete) {
                let paths = (try? await fetchAllLearningPaths(studentId: studentId)) ?? []
                let progressMap = Dictionary(uniqueKeysWithValues: completed.map { ($0.contentItemId, $0) })
                let hasCompletePath = paths.contains { path in
                    !path.items.isEmpty && path.items.allSatisfy { progressMap[$0.contentItemId] != nil }
                }
                if hasCompletePath {
                    try await awardBadge(studentId: studentId, type: .pathComplete)
                }
            }
        } catch {
            // Badge awarding is best-effort — silent failure is acceptable
        }
    }
}
