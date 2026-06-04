# Models Context

## Purpose
Store Codable and SwiftData model types used by the EduAssist app.

## Contents
- User, role, learning path, content, progress, messaging, recommendation, safety, and reporting data models.
- Static data providers for career exploration and test prep.
- Cache model definitions used by offline storage.

## Conventions
- Keep model fields aligned with Firestore document shapes.
- Prefer optional properties for additive backend fields that may not exist on older documents.
- Do not add persistence side effects or network access to model types.
- Log model additions or edits in `EduAssistall/Models/LOG.md`.
