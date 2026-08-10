# EduAssist macOS Screen Proposal

This proposal keeps the macOS app focused on teacher and administrator productivity. The iOS/iPadOS app remains the primary student-facing experience, while macOS should feel like a desktop command center for planning, monitoring, review, and compliance.

## 1. Teacher Command Center

Purpose: Give teachers a single morning-start screen.

Suggested layout:
- Left sidebar: Classes, students, messages, documents, settings.
- Main pane: Class snapshot, students needing attention, active sessions, weak standards, pending approvals.
- Right inspector: Selected student summary with recent flags, progress, parent update draft, and quick actions.

Why it saves time: Replaces several tab hops with one scan-and-act workspace.

## 2. Live Classroom Monitor

Purpose: Make active AI sessions easier to supervise from a laptop.

Suggested layout:
- Dense table of students with status, last activity, current mode, frustration/safety indicators, and pause/resume controls.
- Detail split view for transcript preview, teacher hint, and lock reason.
- Filters for active only, needs attention, silent support, and locked.

Why it saves time: Teachers can supervise a whole class without opening each student individually.

## 3. Teacher Assist Analytics

Purpose: Turn the new Teacher Assist feature into a richer desktop analytics screen.

Suggested layout:
- Standards mastery heatmap across the top.
- Student risk table with sortable columns: completion, test average, minutes, stale activity, flags.
- Small-group board with drag-and-drop movement between Reteach, Practice, and Enrichment.
- Draft panels for parent updates, interventions, and accommodations.

Why it saves time: Makes grouping, intervention planning, and parent communication visible in one place.

## 4. Curriculum And Assignment Builder

Purpose: Make desktop planning faster than tablet planning.

Suggested layout:
- Three-column builder: content library, assignment sequence, student/group targeting.
- Drag-and-drop content into a learning path.
- Standards and grade filters pinned at the top.
- Preview drawer showing what the student will see.

Why it saves time: Desktop drag-and-drop is the natural place to build and revise multi-step learning paths.

## 5. Document Review And Compliance

Purpose: Support district and homeschool document retention without exposing complexity.

Suggested layout:
- Unified document queue for SharePoint or Firebase backend.
- Pending AI-generated documents with approve/reject actions.
- Filters by type: lesson plan, parent letter, policy, curriculum, student content.
- Compliance status strip showing backend, retention mode, and last sync.

Why it saves time: Keeps teacher approval guardrails visible without making teachers think about storage plumbing.

## 6. School Or Homeschool Setup

Purpose: Make onboarding and IT setup clearer on the larger screen.

Suggested layout:
- Segmented setup path: School District, Non-M365 School, Homeschool.
- Backend choice card: SharePoint or Firebase.
- Data retention, document approval, teacher/parent roles, and demo data steps.
- Readiness checklist before inviting students.

Why it saves time: Reduces support burden by making the setup path explicit for each customer type.

## Recommended First macOS Release Scope

For a first polished macOS pass, prioritize:
1. Teacher Command Center
2. Live Classroom Monitor
3. Teacher Assist Analytics
4. Document Review And Compliance

Defer the full drag-and-drop assignment builder until the core desktop navigation and data loading are stable.
