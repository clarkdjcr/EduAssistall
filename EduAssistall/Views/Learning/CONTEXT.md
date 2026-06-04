# Learning Views Context

## Purpose
Store student and teacher learning path, content catalog, content item, and quiz screens.

## Contents
- Student learning path list and detail views.
- Content item display, content catalog, and teacher learning path creation screens.
- Quiz question creation and student quiz-taking views.

## Conventions
- Keep student-facing assigned content readable inside the app when the backing content is EduAssist-native.
- Use external links only for real web URLs.
- Preserve progress updates through `FirestoreService.shared.saveProgress`.
- Log learning view additions or edits in `EduAssistall/Views/Learning/LOG.md`.
