# Functions Context

## Purpose
Store Firebase Cloud Functions for EduAssist backend workflows, AI generation, safety checks, monitoring, notifications, and document storage integrations.

## Contents
- `index.js` exports callable, HTTP, Firestore-triggered, and scheduled Cloud Functions.
- `package.json` and lockfile define the Node.js runtime dependencies.
- Firebase deployment artifacts and local function configuration files live here.

## Conventions
- Keep secrets in Firebase/Google Secret Manager or environment configuration, never in source.
- Use Admin SDK writes for server-owned collections and deny direct client writes in `firestore.rules`.
- Keep function exports grouped by workflow area when practical.
- Validate JavaScript syntax with `node --check functions/index.js` after edits.
