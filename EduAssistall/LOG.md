# App Source Log

## 2026-06-03T15:12:08 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added required context and activity log files for the Swift app source directory.
**Details:** Created `EduAssistall/CONTEXT.md` and `EduAssistall/LOG.md` before adding the standards update review UI.

## 2026-06-03T15:12:08 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added an admin standards update review screen to the app.
**Details:** Created `EduAssistall/Views/Settings/StandardsUpdateReviewView.swift` and wired it into Settings for admin users.

## 2026-06-03T21:48:24 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added required context and activity log files for model and learning view directories.
**Details:** Created `EduAssistall/Models/CONTEXT.md`, `EduAssistall/Models/LOG.md`, `EduAssistall/Views/Learning/CONTEXT.md`, and `EduAssistall/Views/Learning/LOG.md`.

## 2026-06-03T21:48:24 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Fixed student lesson assignments so they open inside EduAssist.
**Details:** Updated `EduAssistall/Models/ContentItem.swift` and `EduAssistall/Views/Learning/ContentItemView.swift` to decode and render `lessonPlanText` for EduAssist-native assignments.

## 2026-06-03T21:53:34 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added share-sheet support for student lesson assignments.
**Details:** Updated `EduAssistall/Views/Learning/ContentItemView.swift` so assignment text can be shared to local apps through `ShareLink`.

## 2026-06-03T21:55:00 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added required context and activity log files for student views.
**Details:** Created `EduAssistall/Views/Student/CONTEXT.md` and `EduAssistall/Views/Student/LOG.md`.

## 2026-06-03T21:55:00 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Fixed learning journal entries that displayed raw JSON.
**Details:** Updated `EduAssistall/Models/LearningJournalEntry.swift` and `EduAssistall/Views/Student/LearningJournalView.swift` so JSON-shaped summaries render as plain student-facing text.

## 2026-06-04T15:04:05 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added required context and activity logs for additional app source directories.
**Details:** Created convention files for `EduAssistall/Extensions`, `EduAssistall/Views/Curriculum`, `EduAssistall/Views/Messages`, and `EduAssistall/Views/TestPrep`.

## 2026-06-04T15:04:05 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Improved macOS modal sizing across teacher, curriculum, messaging, and test-prep workflows.
**Details:** Added a reusable macOS sheet sizing helper and applied it to high-use sheets so desktop popups better match the roomy iOS/iPad workflows.

## 2026-06-07T20:27:36 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Clarified signup, invite, onboarding, and legacy link language.
**Details:** Updated auth, onboarding, dashboard, parent link, profile link, and teacher invite views so open registration is parent-only and student accounts are teacher-invited.

## 2026-06-22T11:48:02 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added teacher behavior and documentation support.
**Details:** Created a teacher-owned documentation record model and behavior documentation workflow, added Firestore save/fetch support, and wired the workflow into the teacher dashboard.

## 2026-06-22T12:03:04 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Fixed social view picker selections for SwiftUI compilation.
**Details:** Updated `Views/Social/KudosView.swift` and `Views/Social/TeacherSpotlightView.swift` to select student IDs instead of whole `UserProfile` values, avoiding Hashable conformance requirements.

## 2026-06-22T12:06:31 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Fixed quest task progress naming collision.
**Details:** Updated `Views/Discovery/QuestsView.swift` so `TaskRow` uses `progressFraction` for display math instead of redeclaring `progress`.

## 2026-06-22T12:24:13 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Corrected recommendation review messaging for lesson workflows.
**Details:** Updated `Views/Recommendations/RecommendationDetailView.swift` so lesson-plan and teaching-day approval no longer claims that students can see the item before assignment.
