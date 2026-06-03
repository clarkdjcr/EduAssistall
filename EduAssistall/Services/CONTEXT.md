# Services Context

## Purpose
Store app service wrappers for Firebase, Cloud Functions, connectivity, caching, security, notifications, exports, and other cross-view operations.

## Contents
- Firebase Firestore and Cloud Functions clients.
- Local cache, connectivity, audit, notification, PDF, and verification services.

## Conventions
- Keep network and Firebase details out of views when a reusable service method fits.
- Prefer async/await APIs.
- Keep platform-only APIs behind guards or existing compatibility helpers.
- Log service edits in `EduAssistall/Services/LOG.md`.
