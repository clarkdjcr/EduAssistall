# EduAssist Architecture Diagram

## System Overview

EduAssist is a native iOS/iPadOS SwiftUI K-12 education platform with Firebase as the complete backend. The app features role-based experiences (Student, Teacher, Parent, Admin) and an AI-powered student companion chat powered by Anthropic Claude.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              iOS/iPadOS App                                 │
│                          (SwiftUI + Firebase SDK)                            │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Firebase Backend                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────────┐ │
│  │   Auth       │  │  Firestore   │  │    Cloud Functions (Node.js)      │ │
│  │              │  │              │  │  ┌──────────────────────────────┐  │ │
│  │ • Email/Pass │  │ • 30+        │  │  │ • askCompanion (AI Chat)     │  │ │
│  │ • Google     │  │   Collections │  │  │ • generateLessonPlan        │  │ │
│  │ • Microsoft  │  │ • Real-time  │  │  │ • generateParentLetter      │  │ │
│  │ • COPPA      │  │   Listeners  │  │  │ • curateContent             │  │ │
│  │   Compliance │  │ • Security   │  │  │ • bulkInviteStudents        │  │ │
│  └──────────────┘  │   Rules      │  │  │ • NFR Functions             │  │ │
│                    └──────────────┘  │  └──────────────────────────────┘  │ │
│                                       │  ┌──────────────────────────────┐  │ │
│                                       │  │ • SharePoint Integration     │  │ │
│                                       │  │ • OpenAI Integration         │  │ │
│                                       │  │ • SendGrid Email             │  │ │
│                                       │  └──────────────────────────────┘  │ │
│                                       └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
            ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
            │   Anthropic  │   │   Microsoft  │   │   SendGrid   │
            │   Claude API │   │   Graph API  │   │   Email API  │
            │   (AI Chat)  │   │ (SharePoint) │   │  (Notifications)│
            └──────────────┘   └──────────────┘   └──────────────┘
```

---

## App Architecture (iOS Side)

### State Machine & Navigation

```
EduAssistallApp.init()
  │
  ├─ FirebaseApp.configure()
  ├─ SwiftData ModelContainer setup (OfflineCacheService)
  ├─ @State private var authViewModel = AuthViewModel()
  │
  └─ AppRootView
       │
       ├─ AuthViewModel.startListening() (called in .task)
       │
       └─ Switch on authState:
            │
            ├─ .loading → ProgressView
            ├─ .unauthenticated → AuthCoordinatorView
            ├─ .pendingParentalConsent → PendingParentalConsentView
            ├─ .onboarding → OnboardingCoordinatorView
            │    │
            │    └─ Role-based onboarding:
            │         ├─ Student: VARK assessment → interests → grade
            │         ├─ Teacher: Class code generation
            │         └─ Parent: Link child by email
            │
            └─ .authenticated → MainTabView
                 │
                 └─ Switch on profile.role:
                      │
                      ├─ .student → StudentTabView
                      │    ├─ Home (StudentDashboardView)
                      │    ├─ Learning (LearningPathsView)
                      │    ├─ Companion (CompanionView - AI Chat)
                      │    ├─ Progress (StudentProgressView)
                      │    └─ Profile (ProfileSettingsView)
                      │
                      ├─ .teacher → TeacherTabView
                      │    ├─ Roster (TeacherDashboardView)
                      │    ├─ Monitor (TeacherMonitorView)
                      │    ├─ Create (TeacherDocumentsTabView)
                      │    │    ├─ Generate Lesson Plan
                      │    │    ├─ Generate Parent Letter
                      │    │    ├─ Assign to Students
                      │    │    ├─ Grading Setup
                      │    │    ├─ Curriculum Library
                      │    │    └─ Pending Recommendations
                      │    ├─ Assist (TeacherAssistView)
                      │    ├─ Messages (MessagesListView)
                      │    └─ Settings (ProfileSettingsView)
                      │
                      ├─ .parent → ParentTabView
                      │    ├─ Overview (ParentDashboardView)
                      │    ├─ Reports (ParentReportsTabView)
                      │    ├─ Messages (MessagesListView)
                      │    └─ Settings (ProfileSettingsView)
                      │
                      └─ .admin → AdminTabView
```

### Service Layer (Singletons)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Service Layer                                │
├─────────────────────────────────────────────────────────────────┤
│ • FirestoreService.shared     - All Firestore CRUD operations   │
│ • CloudFunctionService.shared - Cloud Function calls             │
│ • AuditService.shared         - COPPA audit logging             │
│ • NotificationService.shared   - FCM push notifications (iOS)     │
│ • OfflineCacheService.shared  - SwiftData offline cache         │
│ • ConnectivityService.shared  - Network status monitoring       │
│ • PDFExportService            - Progress report PDF generation   │
│ • SecurityVerificationService- TLS/encryption verification       │
│ • DataResidencyService        - US data residency confirmation   │
│ • IntentClassifierService    - Intent classification            │
│ • LocalDraftService           - Draft content storage            │
│ • StorageService              - Firebase Storage operations      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cloud Functions Architecture

### Main Functions

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cloud Functions (us-central1)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  STUDENT-FACING:                                                │
│  • askCompanion              - AI chat with safety pipeline     │
│  • generateJournalEntry      - Learning journal generation      │
│  • saveJournalReflection     - Student reflection storage       │
│                                                                 │
│  TEACHER-FACING:                                               │
│  • generateLessonPlan        - AI lesson plan generation        │
│  • approveLessonPlanAndGenerateDays - Daily lesson breakdown    │
│  • assignLessonPlan          - Assign to students               │
│  • generateParentLetter      - Parent communication AI          │
│  • curateContent             - Content curation from Khan/EdX    │
│  • bulkInviteStudents        - Bulk student invitation          │
│  • importClassroomRoster     - Google Classroom import          │
│                                                                 │
│  ADMIN/IT-FACING:                                              │
│  • verifySharePointSetup      - IT integration verification      │
│  • createSharePointLists      - SharePoint list creation         │
│  • registerSharePointWebhooks - Webhook registration            │
│  • approveDocument           - Document approval workflow        │
│  • approveStandardsUpdate    - Standards update approval        │
│  • setDocumentBackend        - Switch SharePoint/Firebase        │
│  • setDistrictApiKey         - District Anthropic key config    │
│  • getAIUsageStats           - AI usage dashboard data           │
│                                                                 │
│  NFR (Non-Functional Requirements):                             │
│  • healthCheck               - Uptime monitoring (HTTP)          │
│  • computeLatencyStats       - Hourly p50/p95/p99 calculation    │
│  • runSafetyBenchmark        - Safety classifier testing         │
│  • dailyFirestoreBackup      - Daily DR backup to GCS           │
│                                                                 │
│  TRIGGERS:                                                     │
│  • onRecommendationCreated   - FCM push to linked adults        │
│  • onMessageCreated          - Thread participant notification   │
│  • dailyDigest               - 06:00 UTC teacher email summary   │
│  • sharepointWebhookReceiver - SharePoint change invalidation   │
└─────────────────────────────────────────────────────────────────┘
```

### askCompanion Safety Pipeline

```
User Message
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Auth & Consent Check                                      │
│     • Verify Firebase Auth                                   │
│     • Check companionLocks/{studentId} (kill switch)          │
│     • Verify aiConsentGiven in users/{uid}                    │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Rate Limiting (20 calls/hour per UID)                     │
│     • Firestore transaction on rateLimits/{uid}               │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Input Classifier (FR-100)                                 │
│     • Regex-based (<1ms latency)                              │
│     • BLOCKED: violence, weapons, drugs, sexual               │
│     • NEEDS_REVIEW: bullying, distress, alcohol, answer-seeking│
│     • SAFE: passes through                                     │
│     • Logged to safetyClassifications/{autoId}                │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Distress Detection (FR-103)                               │
│     • Self-harm, bullying, emotional distress patterns        │
│     • If detected:                                            │
│       • Log to criticalSafetyEvents/{eventId} (append-only)   │
│       • Write sessionFlags/{studentId}/flags/{autoId}         │
│       • FCM push to district counselors                       │
│       • Return empathetic response (NO Claude call)           │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  5. PII Detection & Redaction (FR-104)                       │
│     • Phone, email, SSN, card, address, name, URL, ZIP       │
│     • Replace with [REDACTED:<type>]                          │
│     • If PII detected: return redirect message                │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Frustration Detection (FR-201)                           │
│     • Confusion, disengagement, relevance_challenge patterns  │
│     • Fire-and-forget write to sessionFlags/{studentId}       │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  7. Context Fetching (Parallel)                               │
│     • learningProfiles/{studentId}                            │
│     • learningPaths (active)                                  │
│     • learningGoals (in progress)                             │
│     • districtConfig/{districtId} (blocked topics)            │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  8. District Topic Block Check (FR-102/105)                   │
│     • district-wide blocked topics                            │
│     • grade-band specific blocked topics (K-2, 3-5, 6-8, 9-12)│
│     • Throw error if match found                              │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  9. Grounding Fetch (Parallel, Degrades Gracefully)          │
│     • SharePoint OR Firebase (per districtConfig)             │
│     • StudentContent list (grade + subject filter)            │
│     • Policies library (system prompt context)               │
│     • Cached in-process (30min TTL) + webhook invalidation    │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  10. System Prompt Construction                               │
│      • Base: EduAssist AI persona                             │
│      • Static blocked topics                                   │
│      • District blocked topics                                 │
│      • Learning style (VARK)                                  │
│      • Grade level                                            │
│      • Active learning path                                   │
│      • Student interests                                      │
│      • Active learning goals (FR-301)                         │
│      • Interaction mode (FR-003)                              │
│      • Response style (FR-203)                                │
│      • Grounding context (curriculum, standards)              │
│      • Recent milestones (FR-002)                              │
│      • Policies context                                       │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  11. Anthropic Claude API Call                                │
│      • Model: claude-sonnet-4-6                               │
│      • District key or global key (Secret Manager)             │
│      • Word limit by grade band (FR-008)                      │
│      • Truncate to sentence boundary if over limit            │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  12. Output Classifier (FR-101)                              │
│      • Harmful instructions, opinions, politics                │
│      • BLOCKED: throw error                                   │
│      • NEEDS_REVIEW: log but deliver                          │
│      • Logged to safetyClassifications/{autoId}                │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  13. Response Processing                                      │
│      • Batch write to conversations/{studentId}/messages      │
│      • Write to aiAuditLog (FR-G6)                            │
│      • Write to performanceMetrics (NFR-001)                 │
│      • Return reply to iOS app                                │
└─────────────────────────────────────────────────────────────┘
```

---

## Firestore Collections

### Core User & Profile Data

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `users/{uid}` | Firebase Auth UID | UserProfile (role, email, display name, consent flags, timezone, COPPA fields) |
| `learningProfiles/{studentId}` | Student UID | LearningProfile (VARK style, grade, interests, RTI tier, interaction modes) |
| `studentAdultLinks/{linkId}` | `{adultId}_{studentId}` | Teacher/parent → student relationships (confirmed, archived, school year) |

### Learning Content

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `learningPaths/{pathId}` | UUID | Ordered content sequences assigned to students |
| `contentItems/{itemId}` | UUID | Shared catalog of video/article/quiz items |
| `studentProgress/{studentId_contentItemId}` | Composite ID | Completion status per item per student |
| `quizQuestions/{id}` | UUID | Quiz questions linked to content items |
| `quizAttempts/{id}` | UUID | Student quiz attempt records |
| `recommendations/{recId}` | UUID | AI-generated content recommendations for students |

### AI Companion

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `conversations/{studentId}/messages/{msgId}` | Auto ID | AI companion chat history (one conversation per student) |
| `companionLocks/{studentId}` | Student UID | Kill-switch lock state (real-time listener in CompanionView) |
| `activeSessions/{studentId}` | Student UID | Live session tracking (FR-200) |
| `sessionFlags/{studentId}/flags/{autoId}` | Auto ID | Educator-visible frustration/safety flags (FR-201) |
| `teacherHints/{studentId}` | Student UID | Teacher intervention hints (FR-204) |
| `learningMilestones/{studentId}/milestones/{id}` | UUID | Cross-session achievements (FR-002) |

### Messaging

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `messageThreads/{threadId}/messages/{msgId}` | Auto ID | In-app messaging between teachers/parents/students |

### Goals & Progress

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `learningGoals/{studentId}/goals/{goalId}` | UUID | Student learning goals (FR-301) |
| `studentBadges/{studentId}/earned/{badgeType}` | Badge type | Earned achievement badges |
| `testAttempts/{id}` | UUID | Practice test attempt records |

### Classroom Management

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `classroomConfig/{teacherId}` | Teacher UID | Teacher-configurable AI settings (FR-203) |
| `districtConfig/{districtId}` | District ID | Per-district settings (blocked topics, counselor IDs, document backend) |

### Safety & Compliance

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `safetyClassifications/{autoId}` | Auto ID | Every input/output classification event (verdict, reason, latency) |
| `criticalSafetyEvents/{eventId}` | Auto ID | Distress alerts (append-only, tamper-evident) |
| `auditLogs/{eventId}` | Auto ID | COPPA audit trail (auth events, data export, account deletion) |

### NFR Collections

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `performanceMetrics/{autoId}` | Auto ID | Per-call APM data (fn, latencyMs, gradeBand, timestamp) - NFR-001 |
| `latencyStats/current` | "current" | Hourly p50/p95/p99 snapshot - NFR-001 |
| `healthPing/probe` | "probe" | Heartbeat doc for uptime monitoring - NFR-002 |
| `safetyBenchmarks/{autoId}` | Auto ID | Benchmark run results (TPR, FPR, corpus size) - NFR-004 |
| `drBackupLog/{autoId}` | Auto ID | Daily Firestore export status - NFR-007 |

### Document Backend (SharePoint or Firebase)

| Collection | Document ID | Purpose |
|------------|-------------|---------|
| `groundingContent/{id}` | Auto ID | Firebase-backed student content (alternative to SharePoint) |
| `districtPolicies/{id}` | Auto ID | Firebase-backed policy documents |
| `curriculumContent/{id}` | Auto ID | Firebase-backed curriculum content |
| `officialDocuments/{id}` | Auto ID | Teacher-uploaded documents (Firebase backend) |
| `districtSecrets/{districtId}` | District ID | Per-district Anthropic API key (Secret Manager alternative) |

---

## Data Models

### User Models

**UserProfile**
- `id`: Firebase Auth UID
- `email`: User email (lowercased)
- `displayName`: Display name
- `role`: UserRole (student, teacher, parent, admin)
- `onboardingComplete`: Bool
- `privacyConsentGiven`: Bool
- `aiConsentGiven`: Bool
- `districtId`: String? (for teachers/admins)
- `timezone`: IANA timezone identifier
- `birthYear`: Int? (COPPA for students)
- `parentalConsentStatus`: String? ("pending", "approved", "not_required")
- `parentEmail`: String?

**LearningProfile**
- `studentId`: Student UID
- `learningStyle`: LearningStyle (visual, auditory, kinesthetic, read_write)
- `grade`: String (e.g., "6", "10", "K")
- `interests`: [String]
- `rtiTier`: RTITier (tier1, tier2, tier3)
- `strengths`: [String]
- `challenges`: [String]
- `defaultInteractionMode`: InteractionMode
- `allowedInteractionModes`: [InteractionMode]
- `currentInteractionMode`: InteractionMode
- `responseStyle`: ResponseStyle (standard, encouraging, formal)

### Content Models

**LearningPath**
- `id`: UUID
- `title`: String
- `description`: String
- `studentId`: Student UID
- `createdBy`: Teacher UID
- `items`: [LearningPathItem]
- `isActive`: Bool
- `answerModeEnabled`: Bool (FR-006)

**ContentItem**
- `id`: UUID
- `title`: String
- `description`: String
- `contentType`: ContentType (video, article, quiz)
- `url`: String
- `subject`: String
- `gradeLevel`: String
- `estimatedMinutes`: Int
- `createdBy`: Teacher UID
- `source`: String? (khanacademy, edx)
- `externalId`: String?
- `alignedStandards`: [String]
- `lessonPlanText`: String?

### AI Companion Models

**ChatMessage**
- `id`: Auto ID
- `role`: MessageRole (user, assistant)
- `text`: String
- `createdAt`: Date

**ActiveSession**
- `studentId`: Student UID
- `isActive`: Bool
- `startedAt`: Date
- `lastMessageAt`: Date
- `messageCount`: Int

**SessionFlag**
- `id`: Auto ID
- `studentId`: Student UID
- `type`: SessionFlagType (frustration, off_topic, safety, inactivity)
- `reason`: String
- `messagePreview`: String?
- `acknowledged`: Bool
- `createdAt`: Date

### Safety Models

**LearningMilestone**
- `id`: UUID
- `studentId`: Student UID
- `type`: MilestoneType (contentCompleted, quizPassed, pathFinished)
- `title`: String
- `subject`: String
- `achievedAt`: Date

**LearningGoal**
- `id`: UUID
- `studentId`: Student UID
- `title`: String
- `subject`: String?
- `status`: GoalStatus (notStarted, inProgress, completed)
- `targetDate`: Date?
- `createdAt`: Date

---

## Integration Points

### SharePoint Integration (Microsoft Graph API)

```
┌─────────────────────────────────────────────────────────────┐
│              SharePoint Document Backend                     │
├─────────────────────────────────────────────────────────────┤
│  Lists:                                                      │
│  • StudentContent    - Curriculum grounding by grade/subject  │
│  • Curriculum        - Teacher-approved curriculum            │
│  • OfficialDocuments - Teacher-generated documents            │
│  • Policies          - District policy documents              │
│                                                             │
│  Flow:                                                       │
│  1. Azure AD OAuth (client credentials flow)                 │
│  2. Graph API calls to fetch list items                     │
│  3. Webhook notifications on list changes                   │
│  4. Cache invalidation via Firestore groundingCacheVersion   │
└─────────────────────────────────────────────────────────────┘
```

### Firebase Document Backend (Alternative)

```
┌─────────────────────────────────────────────────────────────┐
│           Firebase Document Backend (Fallback)               │
├─────────────────────────────────────────────────────────────┤
│  Collections:                                                │
│  • groundingContent    - Student content items               │
│  • curriculumContent  - Curriculum items                    │
│  • districtPolicies   - Policy documents                     │
│  • officialDocuments  - Teacher documents                   │
│                                                             │
│  Controlled by districtConfig.documentBackend field          │
└─────────────────────────────────────────────────────────────┘
```

---

## Security & Compliance

### COPPA Compliance

- **Parental Consent**: Under-13 students require parent email approval
- **Audit Trail**: All auth events, data exports, and account deletions logged to `auditLogs`
- **Data Export**: Students/parents can request full data export via `requestDataExport`
- **Data Retention**: Configurable retention periods (FR-402)
- **PII Scanning**: Automated PII detection and redaction (FR-405)

### Safety Pipeline

- **Input Classification**: Blocks violence, weapons, drugs, sexual content
- **Distress Detection**: Self-harm, bullying, emotional distress → counselor alerts
- **PII Redaction**: Phone, email, SSN, address, name, URL, ZIP
- **Output Classification**: Blocks harmful instructions, flags opinions
- **Frustration Detection**: Educator alerts for confusion/disengagement
- **Kill Switch**: Real-time companion lock via `companionLocks`

### Data Residency

- **US-Only**: All data stored in US Firebase regions (FR-401)
- **TLS Verification**: Automatic verification on authentication (FR-400)

---

## NFR (Non-Functional Requirements)

### NFR-001: Performance Monitoring

- **APM**: `performanceMetrics` collection tracks per-call latency
- **Latency Stats**: Hourly p50/p95/p99 computed by `computeLatencyStats`
- **Target**: p95 < 2000ms
- **Alert**: `latencyStats/current.breachingTarget` flag

### NFR-002: Health Monitoring

- **Health Check**: HTTP function writes heartbeat to `healthPing/probe`
- **Uptime**: External monitors call every 30s
- **Response**: `{ status, p95Ms, timestamp }`

### NFR-003: Scalability

- **Cloud Functions**: maxInstances=200, concurrency=80
- **Capacity**: ~16K simultaneous requests
- **Quota Increase**: Available at cloud.google.com/run/quotas

### NFR-004: Safety Benchmarking

- **Function**: `runSafetyBenchmark` (callable by teacher/admin)
- **Corpus**: 22 labeled samples
- **Targets**: TPR ≥ 99.5%, FPR < 0.5%
- **Results**: Written to `safetyBenchmarks`

### NFR-005: Accessibility

- **Settings**: Dyslexia font, high contrast, large text, reduce motion
- **Storage**: @AppStorage keys (`a11y_*`)
- **Injection**: Environment values at app root
- **Views**: Read via `@Environment(\.dyslexiaFont)` etc.

### NFR-006: Offline Support

- **Cache**: SwiftData (CachedLearningPath, CachedStudentProgress)
- **Service**: OfflineCacheService.shared
- **Detection**: ConnectivityService.shared.isOnline
- **Banner**: Offline banner in MainTabView

### NFR-007: Disaster Recovery

- **Backup**: Daily Firestore export to GCS via `dailyFirestoreBackup`
- **Schedule**: 04:00 UTC
- **Logging**: `drBackupLog` collection
- **Bucket**: `{projectId}-backups/firestore/{date}`

---

## Key Features by Functional Requirement

### Student Features

- **FR-001**: AI companion chat with context-aware responses
- **FR-002**: Cross-session milestone tracking
- **FR-003**: Four interaction modes (Guided Discovery, Co-Creation, Reflective Coaching, Silent Support)
- **FR-006**: Answer mode toggle (educator-controlled)
- **FR-008**: Grade-band word limits
- **FR-200**: Real-time session monitoring
- **FR-201**: Frustration detection & educator alerts
- **FR-301**: Learning goals with progress tracking
- **FR-302**: Learning journal with AI-generated entries

### Teacher Features

- **FR-T5**: AI lesson plan generation
- **FR-T6**: AI parent letter generation
- **FR-203**: Classroom configuration (interaction modes, response styles)
- **FR-204**: Teacher hints (real-time intervention)
- **FR-300**: Dashboard with student sessions, transcripts, flags
- **FR-301**: Goal setting and tracking
- **FR-302**: Journal reflection review

### Safety Features

- **FR-100**: Input safety classifier
- **FR-101**: Output safety classifier
- **FR-102**: Static topic blocks
- **FR-103**: Distress detection with counselor alerts
- **FR-104**: PII detection & redaction
- **FR-105**: Grade-band topic boundaries
- **FR-106**: Companion kill switch

### Admin/IT Features

- **FR-G4**: SharePoint/Firebase document backend
- **FR-G5**: AI usage dashboard
- **FR-G6**: AI audit log
- **FR-400**: TLS verification
- **FR-401**: US data residency
- **FR-402**: Data retention configuration
- **FR-405**: PII scan results

---

## Deployment

### iOS App

```bash
# Build via Xcode (Cmd+B)
# Target: iPad (primary), Mac (compiles but Firebase network calls fail in sandbox)
```

### Cloud Functions

```bash
cd EduAssistall
firebase deploy --only functions

# Update Firestore rules
firebase deploy --only firestore:rules

# View live function logs
firebase functions:log --only askCompanion

# Set/rotate Anthropic API key
firebase functions:secrets:set ANTHROPIC_API_KEY

# Install/update dependencies
cd functions && npm install
```

---

## Technology Stack

### iOS App
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Firebase SDK**: Auth, Firestore, Functions, Messaging, Storage
- **Local Storage**: SwiftData
- **Multi-Platform**: iOS, macOS, visionOS

### Cloud Functions
- **Runtime**: Node.js
- **Framework**: Firebase Functions v2
- **Region**: us-central1
- **AI**: Anthropic Claude (claude-sonnet-4-6)
- **Curriculum AI**: OpenAI GPT-4.1-mini
- **Email**: SendGrid
- **Document Backend**: Microsoft Graph API (SharePoint) OR Firebase Storage + Firestore

### Firebase Services
- **Authentication**: Email/Password, Google, Microsoft/Entra
- **Firestore**: 30+ collections, real-time listeners, security rules
- **Cloud Functions**: 20+ functions (callable, HTTP, scheduled, triggers)
- **Cloud Storage**: Document storage (Firebase backend option)
- **Cloud Messaging**: Push notifications
- **Secret Manager**: API key storage

---

## File Structure

```
EduAssistall/
├── EduAssistall/                    # iOS app source
│   ├── EduAssistallApp.swift        # App entry point
│   ├── AppRootView.swift           # Auth state routing
│   ├── Models/                     # Data models (30+ files)
│   ├── ViewModels/                 # @Observable view models
│   │   └── AuthViewModel.swift     # Auth state machine
│   ├── Views/                      # SwiftUI views (100+ files)
│   │   ├── Main/
│   │   │   └── MainTabView.swift   # Role-based tab navigation
│   │   ├── Auth/                   # Authentication flows
│   │   ├── Onboarding/             # Role-specific onboarding
│   │   ├── Companion/              # AI chat interface
│   │   ├── Teacher/                # Teacher features (20+ files)
│   │   ├── Student/                # Student features
│   │   ├── Settings/               # Settings & admin (11+ files)
│   │   └── ...
│   ├── Services/                   # Singleton services (14 files)
│   │   ├── FirestoreService.swift  # Firestore CRUD
│   │   ├── CloudFunctionService.swift # Cloud Function calls
│   │   └── ...
│   └── Extensions/                 # Platform-conditional extensions
│       ├── Color+Adaptive.swift
│       └── View+InputModifiers.swift
├── functions/                      # Cloud Functions
│   ├── index.js                    # Main function file (5500+ lines)
│   ├── package.json
│   └── __tests__/                  # Function tests
├── firebase.json                   # Firebase configuration
├── firestore.rules                 # Firestore security rules
├── firestore.indexes.json          # Composite indexes
└── storage.rules                  # Storage security rules
```

---

## Summary

EduAssist is a comprehensive K-12 education platform built on SwiftUI and Firebase, featuring:

- **Role-based experiences** for students, teachers, parents, and admins
- **AI-powered companion chat** with multi-layer safety pipeline
- **Curriculum management** with learning paths, content items, and progress tracking
- **Real-time monitoring** for educators (sessions, transcripts, flags)
- **COPPA compliance** with parental consent, audit trails, and data export
- **Flexible document backend** (SharePoint or Firebase)
- **Comprehensive NFR coverage** (performance, health, scalability, accessibility, offline support, DR)

The architecture prioritizes safety, compliance, and educator oversight while providing an engaging, personalized learning experience for students.
