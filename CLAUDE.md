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
| `users/{uid}` | `UserProfile` — role, display name, onboarding flag, `fcmToken` |
| `learningProfiles/{studentId}` | VARK learning style, grade, interests |
| `studentAdultLinks/{linkId}` | Teacher/parent → student relationships |
| `learningPaths/{pathId}` | Ordered content sequences assigned to students |
| `contentItems/{itemId}` | Shared catalog of video/article/quiz items |
| `studentProgress/{studentId_contentItemId}` | Completion status per item per student |
| `conversations/{studentId}/messages/{msgId}` | AI companion chat history |
| `recommendations/{recId}` | AI-generated content recommendations for students |
| `messageThreads/{threadId}/messages/{msgId}` | In-app messaging between teachers/parents/students |
| `auditLogs/{eventId}` | Write-only COPPA audit trail (never read back in app) |
| `districtConfig/{districtId}` | Per-district settings: `blockedTopics: string[]`, etc. Read on every `askCompanion` call so changes propagate within 60 s |
| `safetyClassifications/{autoId}` | Every input/output classification event: verdict, reason, latencyMs, classifierVersion |
| `learningMilestones/{studentId}/milestones/{id}` | Cross-session achievements (content completed, quiz passed, path finished) injected into companion system prompt on returning sessions (FR-002) |
| `companionLocks/{studentId}` | Kill-switch lock state; real-time listener in CompanionView fires within ~1s (FR-106) |

`fetchContentItems(ids:)` chunks requests in groups of 30 to stay within Firestore's `whereField in:` limit.

### Cloud Functions

`functions/index.js` (Firebase Functions v2, `us-central1`) exports three functions:

**`askCompanion`** — callable, requires auth:
1. Fetches `learningProfiles/{studentId}` and active `learningPath` in parallel to build a context-aware system prompt
2. Loads last 10 messages from `conversations/{conversationId}/messages` as history
3. Calls `claude-sonnet-4-6` via `@anthropic-ai/sdk` (API key via Secret Manager)
4. Batch-writes both user message and reply to Firestore; returns `{ reply: string }`

**`onRecommendationCreated`** — Firestore trigger on `recommendations/{recId}`: fetches linked adults for the student, collects their `fcmToken` values, sends multicast FCM push.

**`onMessageCreated`** — Firestore trigger on `messageThreads/{threadId}/messages/{msgId}`: notifies thread participants (excluding sender) via FCM.

**`dailyDigest`** — scheduled (06:00 UTC): sends teacher email summary of student alerts and progress via SendGrid.

### Safety & Compliance Pipeline (inside `askCompanion`)

All classifiers run synchronously before Claude is called; latency target < 100 ms each.

| Stage | FR | Behavior |
|---|---|---|
| Input classifier | FR-100 | BLOCKED (violence, weapons, drugs, sexual) or NEEDS_REVIEW (bullying, distress) — rejects before Claude |
| PII detection & redaction | FR-104 | Redacts phone, email, SSN, card, address, name, URL, zip to `[REDACTED:<type>]` |
| Distress detection | FR-103 | Returns empathetic response; emails counselor via SendGrid; writes to `criticalSafetyEvents/{eventId}` (tamper-evident) |
| Output classifier | FR-101 | Blocks harmful instructions in Claude's reply; flags opinions/politics |
| Frustration detection | FR-201 | Fire-and-forget write to `sessionFlags/{studentId}/flags/{autoId}` for educator alerts |

All classification events are written to `safetyClassifications/{autoId}` with verdict, reason, latencyMs, and classifierVersion.

Additional collections used by safety/session features:
- `criticalSafetyEvents/{eventId}` — distress alerts (append-only)
- `sessionFlags/{studentId}/flags/{autoId}` — educator-visible frustration/safety flags
- `activeSessions/{studentId}` — live session tracking (FR-200), written by CompanionView

Additional collections added for NFRs:
- `performanceMetrics/{autoId}` — per-call APM data: `fn`, `latencyMs`, `gradeBand`, `timestamp` (NFR-001)
- `latencyStats/current` — hourly p50/p95/p99 snapshot written by `computeLatencyStats` (NFR-001)
- `healthPing/probe` — heartbeat doc written by `healthCheck` HTTP function (NFR-002)
- `safetyBenchmarks/{autoId}` — benchmark run results: TPR, FPR, corpus size (NFR-004)
- `drBackupLog/{autoId}` — daily Firestore export status records (NFR-007)

### NFR Functions

**`computeLatencyStats`** — scheduled hourly: reads last 60 min of `performanceMetrics`, computes p50/p95/p99, writes to `latencyStats/current`. Sets `breachingTarget: true` if p95 > 2000ms.

**`healthCheck`** — HTTP (unauthenticated): writes heartbeat to Firestore, returns JSON `{ status, p95Ms, timestamp }`. Used by external uptime monitors every 30s (NFR-002).

**`runSafetyBenchmark`** — callable (teacher/admin): runs input+output classifiers against a built-in 22-sample labeled corpus, returns TPR/FPR, writes to `safetyBenchmarks`. NFR-004 target: TPR ≥ 99.5%, FPR < 0.5%.

**`dailyFirestoreBackup`** — scheduled 04:00 UTC: calls Firestore Admin export API to `gs://{projectId}-backups/firestore/{date}`. Requires GCS bucket `{projectId}-backups` to exist. Logs to `drBackupLog`. NFR-007 DR support.

### NFR-005 Accessibility

`AccessibilitySettingsView` (Settings tab) exposes dyslexia-friendly font, high-contrast mode, larger text, and reduce motion toggles. All preferences are persisted via `@AppStorage` with keys `a11y_*` and injected into the SwiftUI environment at app root via custom `EnvironmentKey` values (`dyslexiaFont`, `a11yHighContrast`, `a11yLargeText`, `a11yReduceMotion`). Views that need to adapt to these read them via `@Environment(\.dyslexiaFont)` etc.

The iOS side calls `askCompanion` through `CloudFunctionService.shared` (`Services/CloudFunctionService.swift`). One conversation per student — `conversationId` equals `studentId`.

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

### Supporting Services

| Service | Purpose |
|---|---|
| `AuditService.shared` | Fire-and-forget write to `auditLogs` — call for auth events, data export, account deletion |
| `NotificationService.shared` | iOS-only (`#if os(iOS)`); requests UNUserNotification permission and relays FCM token refreshes to Firestore |
| `OfflineCacheService.shared` | `UserDefaults`-backed JSON cache for learning paths, progress, and content items — used when `ConnectivityService.shared.isOnline` is false |
| `ConnectivityService.shared` | `@Observable` `NWPathMonitor` wrapper; exposes `isOnline: Bool` |
| `PDFExportService` | Generates a `ReportSnapshot` PDF for teacher/parent progress reports |

### Shared Progress Components

`Views/Progress/StudentProgressView.swift` exports reusable components used across multiple views:
- `ProgressRing` — circular progress indicator
- `PathProgressCard` — per-path progress bar card
- `StatRow` — value + label row

`StudentProgressDetailView` is the shared detail view used by both parents (tapping a linked student) and teachers (tapping from Monitor tab).

### Additional View Areas

Beyond the role-based tabs documented above, these view groups exist:
- `Views/Career/` — career explorer with `CareerPath`/`Luminary` models (data from `CareerDataProvider`, no Firestore)
- `Views/TestPrep/` — practice tests using `PracticeTest`/`Standard` models (data from `TestDataProvider`, no Firestore)
- `Views/Messages/` — in-app messaging via `messageThreads` collection
- `Views/Recommendations/` — pending and detail views for AI-generated recommendations
- `Views/Reports/` — report detail view with PDF export via `PDFExportService`
- `Views/Settings/DataPrivacyView.swift` — COPPA data export/delete flow that triggers `AuditService` events
