# Curriculum Views Context

## Purpose
Store curriculum library, upload, source review, and grounding-content screens used by teachers and admins.

## Contents
- Curriculum library browsing and upload views.
- Grounding content metadata and source status UI.

## Conventions
- Keep curriculum actions aligned with approved district content and teacher/admin review workflows.
- Prefer existing Firebase service wrappers and Cloud Functions for backend-owned writes.
- Keep modal layouts usable on iOS, iPadOS, and macOS.
- Log curriculum view edits in `EduAssistall/Views/Curriculum/LOG.md`.
