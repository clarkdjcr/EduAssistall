import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - LocalDraftService

/// Provides two on-device capabilities to reduce cloud costs:
///
/// 1. **History compression** (2B): Summarises recent conversation messages into a
///    compact context string before sending to the cloud, cutting input tokens by ~60–80%.
///
/// 2. **Draft generation** (2C): Generates an immediate on-device first-draft response
///    that CompanionView shows while the authoritative cloud reply is in flight.
///    Returns nil when FoundationModels is unavailable; UI falls back to typing indicator.
actor LocalDraftService {

    static let shared = LocalDraftService()
    private init() {}

    // MARK: - History Compression (2B)

    /// Summarises `messages` into a compact context string (≤ 120 words).
    /// Replaces the raw 40-message history payload sent to the cloud.
    func compressHistory(_ messages: [ChatMessage], gradeLevel: String?) async -> String? {
        guard messages.count >= 4 else { return nil }

        let transcript = messages.suffix(20).map {
            "\($0.role == .user ? "Student" : "AI"): \($0.text)"
        }.joined(separator: "\n")

        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, *) {
            return await summariseWithFoundationModel(transcript)
        }
        #endif
        return simpleTruncation(messages)
    }

    // MARK: - Draft Generation (2C)

    /// Generates a short on-device draft response. Returns nil on older OS or on failure.
    func generateDraft(for message: String, context: String?, gradeLevel: String?) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, *) {
            return await draftWithFoundationModel(message, context: context, gradeLevel: gradeLevel)
        }
        #endif
        return nil
    }

    // MARK: - Foundation Models implementations (iOS 26+)

    #if canImport(FoundationModels)
    @available(iOS 26, macOS 26, *)
    private func summariseWithFoundationModel(_ transcript: String) async -> String? {
        do {
            let session = LanguageModelSession()
            let prompt = """
            Summarise this student–AI conversation in 80 words or fewer. \
            Focus on what the student is working on and key concepts discussed. Write in third person.

            Conversation:
            \(transcript)
            """
            let response = try await session.respond(to: prompt)
            let summary = response.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return summary.isEmpty ? nil : summary
        } catch {
            return nil
        }
    }

    @available(iOS 26, macOS 26, *)
    private func draftWithFoundationModel(
        _ message: String,
        context: String?,
        gradeLevel: String?
    ) async -> String? {
        do {
            let gradePart = gradeLevel.map { " The student is in grade \($0)." } ?? ""
            let contextPart = context.map { " Context: \($0)" } ?? ""
            let session = LanguageModelSession()
            let prompt = """
            You are a helpful educational AI for K-12 students.\(gradePart)\(contextPart)
            Give a brief, encouraging draft answer (2–3 sentences) to: \(message)
            Keep it concise and age-appropriate.
            """
            let response = try await session.respond(to: prompt)
            let draft = response.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return draft.isEmpty ? nil : draft
        } catch {
            return nil
        }
    }
    #endif

    // MARK: - Fallback for pre-iOS 26

    private func simpleTruncation(_ messages: [ChatMessage]) -> String? {
        let recent = messages.suffix(6).map {
            "\($0.role == .user ? "Student" : "AI"): \($0.text.prefix(100))"
        }.joined(separator: " | ")
        return recent.isEmpty ? nil : recent
    }
}
