# EduAssist Context

## Purpose
Host the EduAssist native app, Firebase backend, project documentation, utility scripts, and deployment configuration.

## Contents
- `EduAssistall/` contains the SwiftUI application source.
- `functions/` contains Firebase Cloud Functions.
- `docs/` contains project documentation and curriculum reference materials.
- `scripts/` contains utility scripts for setup, seeding, upload, and parsing work.
- Firebase rules, indexes, and project configuration live at the project root.

## Conventions
- Keep app, backend, documentation, and script paths relative to this project root.
- Do not rename, move, restructure, or delete project assets without explicit confirmation.
- Record system-wide additions or backend/rules changes in `LOG.md`.
- Prefer existing Firebase and SwiftUI service patterns before adding new architecture.
