import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Intent

enum MessageIntent {
    /// Clear educational question — proceed to cloud.
    case educational
    /// Simple factual lookup that may be answerable on-device.
    case simpleFactual
    /// Potential safety/distress signal — must always reach the cloud safety pipeline.
    case safetyConcern
}

// MARK: - IntentClassifierService

/// On-device intent classifier that routes messages to avoid unnecessary cloud calls.
/// iOS 26+: uses FoundationModels for zero-shot classification.
/// Earlier OS: falls back to a fast keyword heuristic (<1ms).
actor IntentClassifierService {

    static let shared = IntentClassifierService()
    private init() {}

    func classify(_ text: String) async -> MessageIntent {
        #if canImport(FoundationModels)
        if #available(iOS 26, macOS 26, *) {
            return await classifyWithFoundationModel(text)
        }
        #endif
        return classifyWithHeuristic(text)
    }

    // MARK: - Foundation Models path (iOS 26+)

    #if canImport(FoundationModels)
    @available(iOS 26, macOS 26, *)
    private func classifyWithFoundationModel(_ text: String) async -> MessageIntent {
        do {
            let session = LanguageModelSession()
            let prompt = """
            Classify this student message into exactly one category: educational, simpleFactual, or safetyConcern.

            Rules:
            - safetyConcern: any mention of self-harm, bullying, distress, dangerous topics, or inappropriate content.
            - simpleFactual: brief factual questions answerable in one sentence (e.g. "What year did WW2 end?").
            - educational: all other learning questions, homework help, concept explanations.

            Reply with only one word: educational, simpleFactual, or safetyConcern.

            Message: \(text)
            """
            let response = try await session.respond(to: prompt)
            let answer = response.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
            if answer.contains("safetyconcern") || answer.contains("safety") { return .safetyConcern }
            if answer.contains("simplefactual") || answer.contains("simple") { return .simpleFactual }
            return .educational
        } catch {
            return classifyWithHeuristic(text)
        }
    }
    #endif

    // MARK: - Keyword heuristic (all OS versions)

    private let safetyKeywords = [
        "kill", "hurt", "harm", "suicid", "self-harm", "cut myself", "bully",
        "weapon", "gun", "bomb", "drug", "cocaine", "porn",
    ]

    private let simpleFactualPrefixes = [
        "what year", "when did", "who was", "what is the capital",
        "how many", "what is the symbol for", "what does", "define",
        "spell ", "what color", "how tall",
    ]

    private func classifyWithHeuristic(_ text: String) -> MessageIntent {
        let lower = text.lowercased()
        if safetyKeywords.contains(where: { lower.contains($0) }) { return .safetyConcern }
        if text.count < 80 && simpleFactualPrefixes.contains(where: { lower.hasPrefix($0) }) { return .simpleFactual }
        return .educational
    }
}
