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

## 2026-06-04T15:56:54 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added the lesson-plan recommendation workflow with daily recommendation approval.
**Details:** Updated the app and Firebase Functions so teacher-generated lesson plans become AI recommendations, approved plans are parsed into daily recommendations, and approved days assign as ordered student learning-path content.

## 2026-06-04T15:56:54 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Failure
**Summary:** Firebase Functions deploy was blocked by expired local Firebase credentials.
**Details:** Ran `firebase deploy --only functions`; Firebase CLI requires `firebase login --reauth` before the new callable can be deployed to `eduassist-b1f49`.

## 2026-06-04T16:04:56 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added private learning journal reflections with opt-in teacher/parent sharing.
**Details:** Updated app, backend, and `firestore.rules` so student reflections are private by default, safety-screened on save, and visible to linked adults only when shared by the student.

## 2026-06-04T16:07:54 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added student writing guidance to the learning journal.
**Details:** Updated the student journal detail view with a collapsible writing guide to support stronger reflection habits.

## 2026-06-04T16:12:33 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Extended the failure-as-feedback concept across tutoring, journaling, and quiz retry flows.
**Details:** Updated AI companion prompts, journal summary prompts, journal writing guidance, and quiz retry UI so missed attempts produce correction steps and reinforce learning beyond memorization.

## 2026-06-06T21:10:01 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Restricted student-visible assigned work to learning paths.
**Details:** Updated `firestore.rules` so intermediate AI recommendations and weekly assignment documents are adult/admin-facing, while students receive teacher-approved work through assigned `learningPaths` and `contentItems`.

## 2026-06-06T21:34:39 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added Firestore composite indexes for student assignment visibility.
**Details:** Updated `firestore.indexes.json` with `learningPaths` student active-path lookup support and `recommendations` student status lookup support.

## 2026-06-07T20:09:25 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Allowed students to archive completed learning paths without deleting logs.
**Details:** Updated `firestore.rules` so a student can mark their own path inactive with archive metadata after completion is handled in the app.

## 2026-06-07T20:27:36 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Tightened role and link rules for invited-student sanity.
**Details:** Updated `firestore.rules` so user roles cannot be changed by ordinary self-writes, and clarified that current teacher/parent links are confirmed after invite or lookup.

## 2026-06-07T20:31:33 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Restricted first-time client profile creation to parent accounts.
**Details:** Updated `firestore.rules` so student and teacher roles cannot be self-declared during open signup.

## 2026-06-22T11:48:02 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added owner-only Firestore rules for teacher documentation records.
**Details:** Updated `firestore.rules` so `teacherDocumentation/{teacherId}/records/{recordId}` can only be read or written by the owning teacher.
