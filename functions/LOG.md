# Functions Log

## 2026-06-03T15:09:27 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added required context and activity log files for the Firebase Functions directory.
**Details:** Created `functions/CONTEXT.md` and `functions/LOG.md` before recording backend curriculum-monitor changes.

## 2026-06-03T15:09:27 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added public standards source monitoring and admin approval workflow support.
**Details:** Updated `functions/index.js` with a weekly scheduled standards monitor, public source hashing, standards update alerts, and admin approval handling.

## 2026-06-03T15:18:43 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Deployed the updated Firebase Functions codebase.
**Details:** `monitorPublicStandardsSources(us-central1)` and `approveStandardsUpdate(us-central1)` were created; the existing function bundle updated successfully.

## 2026-06-03T19:47:28 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added a server-backed lesson plan assignment callable.
**Details:** Updated `functions/index.js` with `assignLessonPlan`, which creates reviewed lesson content and student learning paths through Admin SDK.

## 2026-06-03T19:53:06 — [CONFIG_CHANGE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Deployed the updated Firebase Functions codebase with lesson assignment support.
**Details:** `assignLessonPlan(us-central1)` was created and the existing function bundle updated successfully.

## 2026-06-03T21:17:39 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added an optional OpenAI learning enhancement module for lesson planning.
**Details:** Updated `functions/index.js` so `generateLessonPlan` can call OpenAI with approved curriculum context to generate misconceptions, scaffolds, retrieval practice, formative checks, and source-use cautions when `OPENAI_API_KEY` is configured.

## 2026-06-03T21:55:00 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Hardened learning journal response parsing.
**Details:** Updated `functions/index.js` so `generateJournalEntry` extracts JSON from fenced or wrapped model output before saving summaries.

## 2026-06-04T14:49:14 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Filtered assigned lesson plans into student-facing assignment copy and normalized resource subjects.
**Details:** Updated `functions/index.js` so `assignLessonPlan` stores a shorter student assignment with classwork, homework, and quiz-prep guidance while preserving the reviewed teacher plan separately; `curateContent` now maps Social Studies, ELA, and Technology to appropriate provider searches instead of falling back to math.
