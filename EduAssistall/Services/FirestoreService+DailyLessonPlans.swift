import FirebaseFirestore

extension FirestoreService {

    // MARK: - Fetch

    func fetchDailyLessonPlans(gradeLevel: String? = nil, status: DailyLessonPlanStatus? = nil) async throws -> [DailyLessonPlan] {
        var query: Query = db.collection("dailyLessonPlans").order(by: "dayNumber")
        if let gradeLevel { query = query.whereField("gradeLevel", isEqualTo: gradeLevel) }
        if let status     { query = query.whereField("status",     isEqualTo: status.rawValue) }
        let snap = try await query.getDocuments()
        return snap.documents.compactMap { DailyLessonPlan(from: $0) }
    }

    // MARK: - Update (teacher review / edit)

    func saveDailyLessonPlanEdits(
        id: String,
        editedPrimaryText: String,
        editedAlternativeText: String,
        editedActivities: [String],
        editedStudentPrompt: String,
        teacherNotes: String,
        status: DailyLessonPlanStatus
    ) async throws {
        try await db.collection("dailyLessonPlans").document(id).updateData([
            "editedPrimaryText":     editedPrimaryText,
            "editedAlternativeText": editedAlternativeText,
            "editedActivities":      editedActivities,
            "editedStudentPrompt":   editedStudentPrompt,
            "teacherNotes":          teacherNotes,
            "status":                status.rawValue,
            "updatedAt":             FieldValue.serverTimestamp(),
        ])
    }
}
