# Teacher Views Context

## Purpose
Store teacher-facing workflow screens for roster management, monitoring, document generation, approvals, classroom controls, and lesson planning.

## Contents
- Roster and bulk import views.
- Teacher monitor, session alerts, and transcript views.
- AI document generation and approval views.
- Lesson plan and parent letter workflows.

## Conventions
- Keep teacher workflows task-oriented and role-gated.
- Prefer server-side Cloud Functions for writes that cross security-rule boundaries.
- Keep generated AI outputs reviewable before assignment or parent/student distribution.
- Log teacher view edits in `EduAssistall/Views/Teacher/LOG.md`.
