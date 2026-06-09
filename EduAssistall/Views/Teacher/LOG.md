# Teacher Views Log

## 2026-06-03T19:47:28 — [FILE_CREATE]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added required context and activity log files for the teacher views directory.
**Details:** Created `EduAssistall/Views/Teacher/CONTEXT.md` and `EduAssistall/Views/Teacher/LOG.md` before expanding the lesson plan workflow.

## 2026-06-03T19:47:28 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Expanded lesson plan generation into a teacher workspace with assignment preparation.
**Details:** Updated `GenerateLessonPlanView.swift` to support curriculum source selection, inline review, student selection, and server-backed assignment.

## 2026-06-03T21:07:10 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Fixed the lesson workspace layout so controls stay usable in narrow sheets.
**Details:** Updated `GenerateLessonPlanView.swift` to replace the form layout with responsive workspace sections, wrap weekday controls, and clamp start/end dates.

## 2026-06-03T21:13:31 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added selectable outside-provider resources to the lesson workspace.
**Details:** Updated `GenerateLessonPlanView.swift` so teachers can search Khan Academy, edX, or NASA STEM resources, select items, and include them as supplemental lesson-plan context.

## 2026-06-04T14:49:14 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Cleared stale provider resources when lesson subject or grade changes.
**Details:** Updated `GenerateLessonPlanView.swift` so changing the lesson subject or grade resets selected outside resources and the resource search button names the current subject.

## 2026-06-04T15:04:05 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Improved macOS sizing for teacher workflow modals.
**Details:** Updated `GenerateLessonPlanView.swift`, `GenerateParentLetterView.swift`, and `RosterManagementView.swift` so lesson planning, parent-letter review, roster import, and transfer sheets open wider on macOS.

## 2026-06-04T15:56:54 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added two-stage lesson-plan and daily recommendation approval before assignment.
**Details:** Updated `GenerateLessonPlanView.swift` so teachers approve the AI lesson plan, review AI-parsed teaching days, approve those days, and only then assign to selected students.

## 2026-06-07T20:27:36 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Renamed single-student roster creation as an invitation flow.
**Details:** Updated `AddStudentView.swift` copy so teachers invite students rather than silently creating unmanaged student accounts.

## 2026-06-07T20:34:54 — [FILE_EDIT]
**Actor:** Opal
**Outcome:** Success
**Summary:** Added dynamic readiness descriptions to Teacher Assist.
**Details:** Updated `TeacherAssistView.swift` so each assist feature explains whether it is live now or waiting for roster, assignment, standards, progress, assessment, session, or flag data.
