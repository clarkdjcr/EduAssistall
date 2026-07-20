import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - LearningJournalAIService

/// On-device learning-journal summariser (FR-302).
///
/// Summarises the student's just-completed companion session **locally** via Apple
/// Intelligence (iOS 26+), so the conversation transcript never leaves the device. The
/// caller then writes the entry straight to Firestore via
/// `FirestoreService.saveJournalEntry(_:)`.
///
/// When Apple Intelligence is unavailable (older OS, or the model can't be reached),
/// `generateEntry` returns `nil` — the signal for the caller to fall back to the cloud
/// `generateJournalEntry` path (Claude) so students on older iPads still get a summary.
///
/// The generated entry is always created private and unsubmitted. Sharing with a
/// teacher/parent still happens only through the server `saveJournalReflection` callable,
/// which runs the safety classifiers — that gate is unchanged.
///
/// Mirrors the availability-gated pattern of `TeacherKnowledgeAIService`.
actor LearningJournalAIService {

    static let shared = LearningJournalAIService()
    private init() {}

    /// Number of most-recent messages to summarise (matches the cloud fallback's window).
    private static let transcriptMessageLimit = 20

    /// Generates a journal entry on-device. Returns `nil` when no on-device model is
    /// available, signalling the caller to use the cloud fallback.
    func generateEntry(studentId: String, messages: [ChatMessage]) async -> LearningJournalEntry? {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, *) {
            return await generateWithFoundationModel(studentId: studentId, messages: messages)
        }
        #endif
        return nil
    }

    // MARK: - Foundation Models implementation (iOS 26+)

    #if canImport(FoundationModels)
    @available(iOS 26, macOS 26, *)
    private func generateWithFoundationModel(studentId: String, messages: [ChatMessage]) async -> LearningJournalEntry? {
        let transcript = messages
            .suffix(Self.transcriptMessageLimit)
            .map { "\($0.role == .user ? "Student" : "AI"): \($0.text)" }
            .joined(separator: "\n")
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: """
                You are a learning journal assistant. Given a conversation transcript between a \
                student and an AI tutor, produce a concise learning summary in 2-3 sentences \
                describing what the student accomplished, explored, or learned. If the transcript \
                includes an incorrect attempt, confusion, or retry, frame it as productive learning \
                evidence: name the correction step or strategy the student practiced, without \
                shaming the student. Also extract 3-5 short key topic tags (single words or short \
                phrases).

                Transcript:
                \(transcript)
                """,
                generating: JournalDraft.self
            )
            let draft = response.content
            let summary = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !summary.isEmpty else { return nil }

            let topics = draft.keyTopics
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(5)

            var entry = LearningJournalEntry(
                studentId: studentId,
                summary: summary,
                keyTopics: Array(topics),
                messageCount: messages.count
            )
            // The Firestore create rule requires the entry to start private and unsubmitted;
            // sharing is only ever enabled later through the server saveJournalReflection path.
            entry.reflectionSafetyStatus = "not_submitted"
            return entry
        } catch {
            // Model unavailable / failed — let the caller fall back to the cloud path.
            return nil
        }
    }
    #endif
}

// MARK: - Guided-generation schema (iOS 26+)

#if canImport(FoundationModels)
@available(iOS 26, macOS 26, *)
@Generable
private struct JournalDraft {
    @Guide(description: "A concise 2-3 sentence summary of what the student learned or practiced")
    var summary: String

    @Guide(description: "Three to five short key topic tags, single words or short phrases")
    var keyTopics: [String]
}
#endif
