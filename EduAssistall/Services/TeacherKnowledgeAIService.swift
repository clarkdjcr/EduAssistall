import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - TeacherKnowledgeAIService

/// On-device helper that turns the teacher's selected wiki entries into a compact
/// "enhancement digest" before a lesson plan is generated in the cloud.
///
/// Token minimisation is the point: compressing the relevant entries on-device
/// (Apple Intelligence, iOS 26+) means the cloud model receives a tight ~600-character
/// digest instead of full entry bodies. On devices without Apple Intelligence it falls
/// back to a deterministic, bounded summary — still small, just not model-compressed.
///
/// Mirrors the availability-gated pattern of `LocalDraftService`.
actor TeacherKnowledgeAIService {

    static let shared = TeacherKnowledgeAIService()
    private init() {}

    /// Hard ceiling on the digest length sent to the cloud, regardless of path.
    private static let maxDigestCharacters = 700

    /// Builds a compact enhancement digest from already-selected wiki entries.
    /// Returns nil when there is nothing usable to send.
    func buildDigest(from entries: [TeacherWikiEntry]) async -> String? {
        let usable = entries.filter { !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !usable.isEmpty else { return nil }

        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, *) {
            if let compressed = await compressWithFoundationModel(usable) {
                return String(compressed.prefix(Self.maxDigestCharacters))
            }
        }
        #endif
        return deterministicDigest(usable)
    }

    // MARK: - Journal → Wiki distillation

    /// Distills a private journal reflection into a *draft* wiki entry the teacher reviews
    /// before saving. Runs on-device (Apple Intelligence) when available; otherwise returns a
    /// deterministic draft. The returned entry is NOT persisted — the caller presents it for
    /// teacher approval, keeping a human in the loop before anything becomes AI-facing.
    func distillJournalToWikiDraft(_ journal: TeacherJournalEntry, teacherId: String) async -> TeacherWikiEntry? {
        let trimmed = journal.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, *) {
            if let draft = await distillWithFoundationModel(trimmed, teacherId: teacherId, journalId: journal.id) {
                return draft
            }
        }
        #endif
        return deterministicDraft(from: journal, teacherId: teacherId)
    }

    // MARK: - Foundation Models implementation (iOS 26+)

    #if canImport(FoundationModels)
    @available(iOS 26, macOS 26, *)
    private func distillWithFoundationModel(_ reflection: String, teacherId: String, journalId: String) async -> TeacherWikiEntry? {
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: """
                Turn this teacher's private reflection into a reusable teaching insight for a wiki. \
                Extract one actionable idea (an analogy, hook, common misconception, or pacing tip). \
                Do not invent standards or curriculum.

                Reflection:
                \(reflection)
                """,
                generating: WikiInsightDraft.self
            )
            let draft = response.content
            let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let body = draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !body.isEmpty else { return nil }
            return TeacherWikiEntry(
                teacherId: teacherId,
                title: title.isEmpty ? "Teaching insight" : title,
                body: body,
                tags: draft.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
                applyToGeneration: true,
                sourceJournalEntryId: journalId
            )
        } catch {
            return nil
        }
    }

    @available(iOS 26, macOS 26, *)
    private func compressWithFoundationModel(_ entries: [TeacherWikiEntry]) async -> String? {
        let source = entries.map { entry in
            let header = entry.title.isEmpty ? "Note" : entry.title
            return "- \(header): \(entry.body)"
        }.joined(separator: "\n")

        do {
            let session = LanguageModelSession()
            let prompt = """
            You are condensing a teacher's personal teaching notes into a brief enhancement \
            brief for a lesson-plan generator. In 90 words or fewer, capture only the actionable \
            teaching moves: analogies, hooks, common student misconceptions, pacing tips, and \
            engagement ideas. Do not invent standards or curriculum. Write terse phrases, not prose.

            Teacher notes:
            \(source)
            """
            let response = try await session.respond(to: prompt)
            let digest = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return digest.isEmpty ? nil : digest
        } catch {
            return nil
        }
    }
    #endif

    // MARK: - Fallback for pre-iOS 26 / unavailable model

    /// Draft used when Apple Intelligence is unavailable: title from the first line/sentence,
    /// body verbatim. The teacher edits before saving, so a rough draft is fine.
    private func deterministicDraft(from journal: TeacherJournalEntry, teacherId: String) -> TeacherWikiEntry {
        let body = journal.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstChunk = body
            .components(separatedBy: CharacterSet(charactersIn: ".\n"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = firstChunk.isEmpty ? "Teaching insight" : String(firstChunk.prefix(60))
        return TeacherWikiEntry(
            teacherId: teacherId,
            title: title,
            body: body,
            tags: journal.tags,
            applyToGeneration: true,
            sourceJournalEntryId: journal.id
        )
    }

    private func deterministicDigest(_ entries: [TeacherWikiEntry]) -> String? {
        // Budget the character ceiling across the selected entries.
        let perEntry = max(120, Self.maxDigestCharacters / max(entries.count, 1))
        let lines = entries.map { entry -> String in
            let header = entry.title.isEmpty ? "Note" : entry.title
            let body = entry.body
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return "- \(header): \(String(body.prefix(perEntry)))"
        }
        let joined = lines.joined(separator: "\n")
        let bounded = String(joined.prefix(Self.maxDigestCharacters))
        return bounded.isEmpty ? nil : bounded
    }
}

// MARK: - Guided-generation schema (iOS 26+)

#if canImport(FoundationModels)
@available(iOS 26, macOS 26, *)
@Generable
private struct WikiInsightDraft {
    @Guide(description: "A concise title naming the teaching insight, at most 8 words")
    var title: String

    @Guide(description: "The actionable teaching insight in 1-3 sentences: an analogy, hook, common misconception, or pacing tip")
    var summary: String

    @Guide(description: "Two to four short topical tags")
    var tags: [String]
}
#endif
