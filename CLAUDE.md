# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**EduAssist** is a native iOS/iPadOS SwiftUI app for K-12 education. Firebase is the entire backend (Auth, Firestore, Cloud Functions). Claude AI powers the student companion chat via a Cloud Function — the API key is never in the iOS app.

**Xcode source root:** `EduAssistall/EduAssistall/`
**Firebase Functions:** `EduAssistall/functions/` (Node.js)
**Firebase project ID:** `eduassist-b1f49`
**Test target:** iPad (primary) — the Mac build compiles but Firebase network calls fail in the macOS sandbox.

## Build & Deploy Commands

```bash
# Deploy Cloud Function after changes
cd EduAssistall && firebase deploy --only functions

# Update Firestore security rules
cd EduAssistall && firebase deploy --only firestore:rules

# View live function logs
firebase functions:log --only askCompanion

# Set/rotate the Anthropic API key secret
cd EduAssistall && firebase functions:secrets:set ANTHROPIC_API_KEY

# Install/update function dependencies
cd EduAssistall/functions && npm install
```

Build the iOS app via Xcode (Cmd+B). There are no unit tests beyond the default stubs.

## Architecture

### Auth & Navigation State Machine

`AuthViewModel` (`ViewModels/AuthViewModel.swift`) is an `@Observable` class injected at the root via `.environment(authViewModel)`. It drives all navigation through the `AuthState` enum:

```
.loading → .unauthenticated → .onboarding(UserProfile) → .authenticated(UserProfile)
```

**Critical:** `FirebaseApp.configure()` runs in `EduAssistallApp.init()`, but `@State private var authViewModel` is evaluated before `init()` body. Therefore `AuthViewModel.init()` must NOT touch Firebase. Firebase listening starts via `authViewModel.startListening()` called in `.task` on the root view. Never move Firebase initialization back into `AuthViewModel.init()`.

### Role-Based Tab Structure

`MainTabView` switches on `profile.role` and renders one of three tab structures:

- **Student:** Home → Learning → Companion (AI chat) → Progress → Profile
- **Teacher:** Roster (dashboard) → Monitor → Reports (placeholder) → Messages (placeholder) → Settings
- **Parent:** Overview → Reports (placeholder) → Messages (placeholder) → Settings

`PlaceholderView` is used for tabs not yet implemented.

### Firestore Service Layer

All Firestore access goes through `FirestoreService.shared` (`Services/FirestoreService.swift`) — a singleton using `async/await`. Collections:

| Collection | Purpose |
|---|---|
| `users/{uid}` | `UserProfile` — role, display name, onboarding flag |
| `learningProfiles/{studentId}` | VARK learning style, grade, interests |
| `studentAdultLinks/{linkId}` | Teacher/parent → student relationships |
| `learningPaths/{pathId}` | Ordered content sequences assigned to students |
| `contentItems/{itemId}` | Shared catalog of video/article/quiz items |
| `studentProgress/{studentId_contentItemId}` | Completion status per item per student |
| `conversations/{studentId}/messages/{msgId}` | AI companion chat history |

`fetchContentItems(ids:)` chunks requests in groups of 30 to stay within Firestore's `whereField in:` limit.

### Cloud Function (AI Companion)

`functions/index.js` exports one callable function `askCompanion`. It:
1. Requires Firebase Auth (`request.auth`)
2. Fetches `learningProfiles/{studentId}` and the student's active `learningPath` in parallel to build a context-aware system prompt
3. Loads the last 10 messages from `conversations/{conversationId}/messages` as history
4. Calls `claude-sonnet-4-6` via `@anthropic-ai/sdk`
5. Persists both the user message and AI reply to Firestore via batch write
6. Returns `{ reply: string }`

The iOS side calls this through `CloudFunctionService.shared` (`Services/CloudFunctionService.swift`) using `FirebaseFunctions`. One conversation per student — `conversationId` equals `studentId`.

### Multi-Platform Target Workarounds

The Xcode target includes iOS, macOS, and visionOS. Several APIs are iOS-only. All platform conditionals are centralized in two extension files — **do not use `#if os(iOS)` inline in views**:

- `Extensions/Color+Adaptive.swift` — `Color.appBackground`, `Color.appSecondaryBackground`, `Color.appGroupedBackground`, `Color.appSecondaryGroupedBackground`
- `Extensions/View+InputModifiers.swift` — `.emailInput()`, `.newPasswordInput()`, `.passwordInput()`, `.nameInput()`, `.inlineNavigationTitle()`, `.hideBackButton()`

When using `.listStyle(.insetGrouped)`, wrap it: `#if os(iOS) .listStyle(.insetGrouped) #else .listStyle(.inset) #endif` — this is the one case that can't be abstracted into an extension cleanly.

### SourceKit False Positives

SourceKit regularly reports "Cannot find type X in scope" for types defined in other files. These are **not real compile errors** — they clear on a full Xcode build (Cmd+B). Do not be misled by these when editing files.

### Onboarding Flow

Role determines the onboarding path in `OnboardingCoordinatorView`:
- **Student:** VARK assessment (8 questions) → interests selection → grade selection → complete
- **Teacher:** `TeacherSetupView` (class code generation)
- **Parent:** `ParentSetupView` (link child by email)

Onboarding completion sets `UserProfile.onboardingComplete = true` in Firestore, which transitions `AuthState` from `.onboarding` to `.authenticated`.

### Shared Progress Components

`Views/Progress/StudentProgressView.swift` exports reusable components used across multiple views:
- `ProgressRing` — circular progress indicator
- `PathProgressCard` — per-path progress bar card
- `StatRow` — value + label row

`StudentProgressDetailView` is the shared detail view used by both parents (tapping a linked student) and teachers (tapping from Monitor tab).
