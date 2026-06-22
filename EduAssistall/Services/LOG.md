# Services Log

## 2026-06-03T15:12:08 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added required context and activity log files for the services directory.
**Details:** Created `EduAssistall/Services/CONTEXT.md` and `EduAssistall/Services/LOG.md` before adding standards update service access.

## 2026-06-03T15:12:08 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added a Cloud Function client method for standards update approval decisions.
**Details:** Updated `EduAssistall/Services/CloudFunctionService.swift` with `approveStandardsUpdate(alertId:decision:notes:)`.

## 2026-06-03T19:47:28 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added a Cloud Function client method for assigning reviewed lesson plans.
**Details:** Updated `EduAssistall/Services/CloudFunctionService.swift` with `assignLessonPlan(...)`.

## 2026-06-03T21:17:39 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Exposed OpenAI learning enhancement readiness in setup verification.
**Details:** Updated `EduAssistall/Services/CloudFunctionService.swift` to parse `OPENAI_API_KEY` status from `verifySharePointSetup`.

## 2026-06-04T15:56:54 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added Cloud Function clients for lesson-plan approval, daily parsing, and multi-day assignment.
**Details:** Updated `EduAssistall/Services/CloudFunctionService.swift` to return recommendation IDs, fetch daily lesson recommendations, and send approved daily plans during assignment.

## 2026-06-04T16:04:56 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added a Cloud Function client for saving private journal reflections.
**Details:** Updated `EduAssistall/Services/CloudFunctionService.swift` with `saveJournalReflection(...)` so student comments save through the backend safety pipeline.

## 2026-06-07T20:09:25 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added a service method for clearing completed learning paths from active assignments.
**Details:** Updated `FirestoreService.swift` with `archiveLearningPath(pathId:archivedBy:)`, which marks a path inactive while preserving progress records.

## 2026-06-07T20:27:36 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Removed uninvited student fallback profile creation.
**Details:** Updated `AuthViewModel.swift` so open self-registration is parent-only and unknown authenticated users without profiles are initialized as parents, not students.

## 2026-06-22T11:48:02 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added Firestore access for teacher documentation records.
**Details:** Updated `FirestoreService.swift` with owner-scoped save and fetch methods under `teacherDocumentation/{teacherId}/records`.

## 2026-06-22T12:00:31 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Fixed optional decoding for quest progress lookup.
**Details:** Updated `FirestoreService.swift` so `fetchQuestProgress(studentId:questId:)` returns a single optional `QuestProgress` instead of a nested optional from `map`.

## 2026-06-22T12:10:09 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added follow-up status updates for teacher documentation.
**Details:** Updated `FirestoreService.swift` with `updateTeacherDocumentationFollowUpStatus(teacherId:recordId:status:)` so dashboard tasks can be marked resolved.
