# Student Views Context

## Purpose
Store student-facing screens for goals, journal history, and learning reflection features.

## Contents
- `GoalSettingView.swift` for student goals.
- `LearningJournalView.swift` for AI companion session summaries.

## Conventions
- Show student-facing prose rather than raw backend payloads.
- Keep journal summaries concise, readable, and safe for direct student review.
- Use existing Firestore service methods for loading student-owned records.
- Log student view additions or edits in `EduAssistall/Views/Student/LOG.md`.
