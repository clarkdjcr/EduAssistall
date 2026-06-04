# Messages Views Context

## Purpose
Store in-app messaging screens for composing, listing, and reading conversations.

## Contents
- Message thread list and compose screens.
- Conversation detail screens.

## Conventions
- Keep message access scoped to participants through existing Firestore services.
- Preserve role-aware participant labels.
- Keep modal compose flows comfortable on iOS, iPadOS, and macOS.
- Log message view edits in `EduAssistall/Views/Messages/LOG.md`.
