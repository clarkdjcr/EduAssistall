# EduAssist Onboarding Guide

EduAssist supports two document-backend paths:

- **School districts with Microsoft 365:** use SharePoint for curriculum grounding, official document retention, and existing approval workflows.
- **Homeschool families or districts without Microsoft 365:** use Firebase Storage and Firestore. No SharePoint or Microsoft 365 license is required.

Both paths keep the same student safety model: students interact only with the AI companion, while teachers control setup, generated documents, approvals, and student session controls.

---

## Path 1: School District With Microsoft 365

Use this path when the district already has Microsoft 365 and wants EduAssist to read and write district curriculum documents through SharePoint.

### Required Setup

1. Create the district, teacher, student, and parent accounts in EduAssist.
2. Open **Settings -> IT Integration** as a teacher or admin.
3. Set **Document Storage** to **SharePoint (Microsoft 365)**.
4. Complete the SharePoint setup in `docs/SHAREPOINT_INTEGRATION.md`.
5. Register SharePoint webhooks from the IT Integration screen.
6. Verify that SharePoint status indicators are green.

### Content Setup

Prepare these SharePoint libraries:

- `Curriculum`: district curriculum, pacing guides, scope and sequence, standards
- `StudentContent`: student-facing grounding material for companion responses
- `OfficialDocuments`: AI-generated lesson plans and parent letters
- `Policies`: district policy documents, optional but recommended

### Approval Guardrail

AI-generated lesson plans and parent letters are saved with pending approval status. The teacher or district approval workflow must approve them before they are treated as official materials.

---

## Path 2: Homeschool or Non-M365 District

Use this path when the school, co-op, micro-school, or homeschool family does not have SharePoint or does not want to pay for Microsoft 365 licensing.

### Required Setup

1. Create the teacher/adult account in EduAssist.
2. Complete teacher setup with the homeschool name or learning group name as the school name.
3. Open **Settings -> IT Integration**.
4. Set **Document Storage** to **Firebase (no M365 required)**.
5. Confirm the screen shows **Firebase Storage Ready**.
6. Add or import curriculum and grounding content into Firebase.

### Content Setup

Firebase-backed content uses:

- `groundingContent`: student companion grounding material
- `curriculumContent`: teacher lesson-plan grounding material
- `districtPolicies`: policy and boundary text
- `officialDocuments`: AI-generated documents pending teacher approval
- Firebase Storage paths under `grounding/`

For a starter dataset, run:

```bash
FIREBASE_PROJECT=eduassist-b1f49 DISTRICT_ID=<your-district-id> node scripts/seed-firebase-content.js
```

Replace `<your-district-id>` with the district ID shown in the app. For homeschool use, this can be the generated ID for the homeschool or learning group.

### Approval Guardrail

Teacher approval remains required. AI-generated lesson plans and parent letters are stored in `officialDocuments` with `approvalStatus: PendingApproval`. The teacher approves or rejects them from **Documents Approval** in the app.

---

## Common Setup for Both Paths

These steps apply to both SharePoint and Firebase document storage:

1. Configure Firebase Auth, Firestore, Cloud Functions, and Firestore rules.
2. Set the `ANTHROPIC_API_KEY` secret in Firebase Secret Manager.
3. Deploy Cloud Functions.
4. Deploy Firestore rules.
5. Create teacher, student, and parent demo or production accounts.
6. Link students to teachers and parents.
7. Assign learning paths and content.
8. Test the AI companion using a student account.
9. Test teacher controls: monitor, pause/resume companion, reports, document generation, and document approval.

Recommended validation commands:

```bash
firebase deploy --only functions
firebase deploy --only firestore:rules
xcodebuild -project EduAssistall.xcodeproj -scheme EduAssistall -configuration Release -destination 'generic/platform=iOS' build
xcodebuild -project EduAssistall.xcodeproj -scheme EduAssistall -configuration Release -destination 'platform=macOS' build
```

---

## Which Path Should I Choose?

| Environment | Recommended Backend | Reason |
|---|---|---|
| District already using Microsoft 365 | SharePoint | Uses existing licensing, libraries, retention, and approval workflows |
| District without Microsoft 365 | Firebase | Avoids M365 licensing and keeps setup inside EduAssist/Firebase |
| Homeschool family | Firebase | Lowest-friction setup with teacher-controlled approval |
| Micro-school or co-op | Firebase | Works without enterprise Microsoft administration |

When in doubt, choose Firebase first. SharePoint can be enabled later for districts that want Microsoft 365 document governance.
