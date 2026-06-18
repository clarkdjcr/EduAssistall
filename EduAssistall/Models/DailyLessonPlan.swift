import Foundation
import FirebaseFirestore

enum DailyLessonPlanStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case approved
    case assigned

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft:    return "Draft"
        case .approved: return "Approved"
        case .assigned: return "Assigned"
        }
    }
}

struct DailyLessonPlan: Identifiable {
    let id: String
    let dayNumber: Int
    let grade: String
    let gradeLevel: String          // "K", "1"…"12", "9-10", "11-12"
    let standardCode: String
    let standardDescription: String
    let strand: String
    let subStandards: [String]
    let studentAssignment: String
    let evidenceOfLearning: [String]

    // AI-generated suggestions written by the seeding script
    let suggestedPrimaryText: String
    let suggestedAlternativeText: String
    let suggestedActivities: [String]
    let suggestedStudentPrompt: String

    // Teacher-edited overrides (nil until the teacher makes a change)
    var editedPrimaryText: String?
    var editedAlternativeText: String?
    var editedActivities: [String]?
    var editedStudentPrompt: String?
    var teacherNotes: String

    let subject: String
    let sourceFile: String
    var status: DailyLessonPlanStatus
    let createdAt: Date?

    // MARK: - Convenience: resolved content (edited takes priority over suggested)

    var resolvedPrimaryText: String      { editedPrimaryText     ?? suggestedPrimaryText }
    var resolvedAlternativeText: String  { editedAlternativeText ?? suggestedAlternativeText }
    var resolvedActivities: [String]     { editedActivities      ?? suggestedActivities }
    var resolvedStudentPrompt: String    { editedStudentPrompt   ?? suggestedStudentPrompt }

    // MARK: - Firestore init

    init?(from snap: DocumentSnapshot) {
        guard let data = snap.data() else { return nil }
        id                    = snap.documentID
        dayNumber             = data["dayNumber"]             as? Int    ?? 0
        grade                 = data["grade"]                 as? String ?? ""
        gradeLevel            = data["gradeLevel"]            as? String ?? ""
        standardCode          = data["standardCode"]          as? String ?? ""
        standardDescription   = data["standardDescription"]   as? String ?? ""
        strand                = data["strand"]                as? String ?? ""
        subStandards          = data["subStandards"]          as? [String] ?? []
        studentAssignment     = data["studentAssignment"]     as? String ?? ""
        evidenceOfLearning    = data["evidenceOfLearning"]    as? [String] ?? []
        suggestedPrimaryText      = data["suggestedPrimaryText"]      as? String   ?? ""
        suggestedAlternativeText  = data["suggestedAlternativeText"]  as? String   ?? ""
        suggestedActivities       = data["suggestedActivities"]       as? [String] ?? []
        suggestedStudentPrompt    = data["suggestedStudentPrompt"]    as? String   ?? ""
        editedPrimaryText         = data["editedPrimaryText"]         as? String
        editedAlternativeText     = data["editedAlternativeText"]     as? String
        editedActivities          = data["editedActivities"]          as? [String]
        editedStudentPrompt       = data["editedStudentPrompt"]       as? String
        teacherNotes              = data["teacherNotes"]              as? String ?? ""
        subject                   = data["subject"]                   as? String ?? "ELA"
        sourceFile                = data["sourceFile"]                as? String ?? ""
        status = DailyLessonPlanStatus(rawValue: data["status"] as? String ?? "draft") ?? .draft
        createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }

    // MARK: - Composed lesson plan text for assignLessonPlan Cloud Function

    func composedLessonPlanText() -> String {
        var parts: [String] = [
            "# \(grade) ELA — \(standardCode)",
            "",
            "**Standard:** \(standardDescription)",
            "**Strand:** \(strand)",
            "",
            "## Accepted Text",
            "**Primary:** \(resolvedPrimaryText)",
            "**Alternative:** \(resolvedAlternativeText)",
            "",
            "## Activities",
        ]
        for (i, activity) in resolvedActivities.enumerated() {
            parts.append("\(i + 1). \(activity)")
        }
        parts += [
            "",
            "## Student Prompt",
            resolvedStudentPrompt,
        ]
        if !teacherNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts += ["", "## Teacher Notes", teacherNotes]
        }
        return parts.joined(separator: "\n")
    }
}
