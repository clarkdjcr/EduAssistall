# EduAssist Log

## 2026-06-03T15:09:27 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added root context and activity log files required by the repository conventions.
**Details:** Created `CONTEXT.md` and `LOG.md` after discovering the root directory did not yet contain them.

## 2026-06-03T15:09:27 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added security rules for public standards monitoring collections.
**Details:** Updated `firestore.rules` so admins can read `publicStandardsSources`, `standardsUpdateAlerts`, and `standardsMonitorRuns`, while all direct client writes remain blocked.

## 2026-06-03T15:09:27 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added scheduled public standards monitoring and admin approval support to Cloud Functions.
**Details:** Updated `functions/index.js` with `monitorPublicStandardsSources` and `approveStandardsUpdate`.

## 2026-06-03T15:12:08 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Excluded source convention files from the app target bundle.
**Details:** Updated `EduAssistall.xcodeproj/project.pbxproj` so `CONTEXT.md` and `LOG.md` files inside app source directories do not collide as copied app resources.

## 2026-06-03T15:18:43 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Deployed Firestore rules and Cloud Functions for standards update monitoring.
**Details:** Ran `firebase deploy --only firestore:rules,functions`; Firestore rules released, `monitorPublicStandardsSources` and `approveStandardsUpdate` were created, and existing functions were updated successfully.

## 2026-06-03T19:47:28 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Excluded teacher view convention files from the app target bundle.
**Details:** Updated `EduAssistall.xcodeproj/project.pbxproj` so `EduAssistall/Views/Teacher/CONTEXT.md` and `LOG.md` are not copied as app resources.

## 2026-06-03T19:53:06 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Deployed the lesson plan assignment Cloud Function.
**Details:** Ran `firebase deploy --only functions`; `assignLessonPlan(us-central1)` was created and the existing function bundle updated successfully.

## 2026-06-03T21:20:40 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Excluded dashboard convention files from the app target bundle.
**Details:** Updated `EduAssistall.xcodeproj/project.pbxproj` so `EduAssistall/Views/Dashboard/CONTEXT.md` and `LOG.md` are not copied as app resources.

## 2026-06-03T21:48:24 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Excluded model and learning view convention files from the app target bundle.
**Details:** Updated `EduAssistall.xcodeproj/project.pbxproj` so `EduAssistall/Models/CONTEXT.md`, `EduAssistall/Models/LOG.md`, `EduAssistall/Views/Learning/CONTEXT.md`, and `EduAssistall/Views/Learning/LOG.md` are not copied as app resources.

## 2026-06-03T21:55:00 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Excluded student view convention files from the app target bundle.
**Details:** Updated `EduAssistall.xcodeproj/project.pbxproj` so `EduAssistall/Views/Student/CONTEXT.md` and `EduAssistall/Views/Student/LOG.md` are not copied as app resources.

## 2026-06-04T15:04:05 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Excluded additional app-source convention files from the app target bundle.
**Details:** Updated `EduAssistall.xcodeproj/project.pbxproj` so convention files in Extensions, Curriculum, Messages, Student, and TestPrep directories do not collide as copied app resources.
