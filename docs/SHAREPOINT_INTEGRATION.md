# EduAssist × Microsoft SharePoint Integration
### Curriculum-Grounded AI — Built for the Way Districts Already Work

> This guide is for districts that already use Microsoft 365 and want EduAssist connected to SharePoint. Homeschool users, micro-schools, co-ops, and districts without Microsoft 365 should use the Firebase onboarding path in `docs/ONBOARDING.md`.

---

## Why This Matters for Your District

Most AI tools for education are trained on generic internet content and have no idea what your district has decided to teach, how your teachers are expected to teach it, or what standards your curriculum is aligned to. They answer with confidence while ignoring everything your curriculum team spent years building.

**EduAssist is different.** Before the AI writes a single word — whether it is generating a lesson plan for a teacher, answering a student's question, or recommending a resource — it reads your district's own curriculum documents from SharePoint first. The AI does not replace your curriculum. It works from it.

This is not a future feature. It is running today.

---

## What the Integration Does

### For Teachers

**AI-generated lesson plans grounded in your district's curriculum**
When a teacher taps "Generate Lesson Plan," EduAssist fetches the relevant curriculum documents from your SharePoint library — filtered by grade level and subject — downloads the actual content, and passes it to Claude as grounding context. The resulting lesson plan reflects your district's scope and sequence, uses your vocabulary, and cites the specific documents it drew from. The teacher sees the plan in seconds. The plan is automatically saved to your SharePoint OfficialDocuments library in pending-approval status, ready for your existing review workflow.

**Parent letters that reference real student data**
Generated parent communication letters pull from the student's actual progress and learning path data in the app, not from a generic template. They are also saved to SharePoint for recordkeeping.

**Content recommendations aligned to your standards**
When teachers build learning paths, EduAssist searches Khan Academy and edX for videos and articles that match the grade, subject, and topic — curating external resources that supplement your curriculum rather than replace it.

### For Students

**An AI companion that knows your curriculum**
The student AI companion (the "Companion" tab) is grounded in your district's StudentContent SharePoint list. When a student asks a question, the AI checks your curriculum materials for that grade level and subject before responding — so it reinforces what your teachers are teaching, in the way your district has chosen to teach it.

**District policy is always in scope**
Your district's policy documents (from the SharePoint Policies library) are injected into the companion's system prompt, so the AI is always operating within the boundaries your district has set.

### For Administrators

**Every AI-generated document is tracked**
All lesson plans and parent letters written by the AI are saved to SharePoint with full metadata: grade, subject, school, document type, and the curriculum sources the AI used. An audit log in Firestore records every AI generation event for compliance and e-discovery.

**Real-time curriculum updates propagate automatically**
EduAssist registers SharePoint webhooks against your curriculum lists. When your curriculum team updates a document in SharePoint, the companion and lesson plan generator pick up the change within seconds — no redeployment, no manual sync, no delay.

**Your approval workflow stays intact**
AI-generated documents land in SharePoint with `ApprovalStatus: PendingApproval`. Your existing Power Automate flows handle the review and approval process exactly as they do today. EduAssist plugs into your workflow; it does not replace it.

---

## Competitive Differentiation

| Capability | Generic AI Tools | EduAssist |
|---|---|---|
| Grounded in your district's curriculum | No | Yes |
| Reads and cites your actual SharePoint documents | No | Yes |
| Saves output back to SharePoint automatically | No | Yes |
| Respects your existing approval workflow | No | Yes |
| Student AI grounded in district content | No | Yes |
| Real-time curriculum sync via webhooks | No | Yes |
| Full audit trail per AI generation | Rarely | Yes |
| Works with your Microsoft 365 tenant | No | Yes |

No other K-12 AI platform connects the generative AI layer directly to the district's own SharePoint curriculum library — reading from it, writing back to it, and staying in sync with it in real time.

---

## How It Works (Technical Overview)

EduAssist connects to Microsoft SharePoint via the **Microsoft Graph API** using an Azure AD app registration in your tenant. All communication is authenticated with a confidential client credential (client ID + secret) stored in Firebase Secret Manager — never in the app binary and never visible to students or teachers.

```
Teacher taps "Generate Lesson Plan"
        │
        ▼
Cloud Function authenticates with Azure AD
        │
        ▼
Graph API: fetch curriculum docs for grade + subject
        │
        ▼
Download file content (up to 4 KB per document)
        │
        ▼
Claude reads district curriculum → writes lesson plan
        │
        ▼
Graph API: save plan to OfficialDocuments (PendingApproval)
        │
        ▼
Teacher sees plan in app + plan is in SharePoint for review
```

---

## Setup Guide for IT Administrators

### Prerequisites

- Microsoft 365 tenant with SharePoint Online
- Firebase project (provided by EduAssist)
- Azure portal access to create app registrations
- Firebase CLI installed (`npm install -g firebase-tools`)

---

### Step 1 — Create the Azure AD App Registration

1. Sign in to [portal.azure.com](https://portal.azure.com) with a Global Administrator or Application Administrator account.
2. Navigate to **Azure Active Directory → App registrations → New registration**.
3. Set:
   - **Name:** `EduAssist Integration`
   - **Supported account types:** Accounts in this organizational directory only
   - **Redirect URI:** Leave blank (this is a service-to-service app, not user-facing)
4. Click **Register**.
5. On the app overview page, copy:
   - **Application (client) ID** — this is your `AZURE_CLIENT_ID`
   - **Directory (tenant) ID** — this is your `AZURE_TENANT_ID`
6. Go to **Certificates & secrets → New client secret**.
   - Description: `EduAssist Production`
   - Expiry: 24 months (set a calendar reminder to rotate before expiry)
   - Copy the secret **value** immediately — this is your `AZURE_CLIENT_SECRET`. It will not be shown again.
7. Go to **API permissions → Add a permission → Microsoft Graph → Application permissions**. Add:
   - `Sites.Read.All` — read SharePoint site content and curriculum documents
   - `Sites.ReadWrite.All` — write lesson plans and parent letters back to SharePoint
   - `Files.ReadWrite.All` — download and upload document file content
8. Click **Grant admin consent for [your tenant]**.

---

### Step 2 — Identify Your SharePoint Site and List IDs

You need the internal IDs for your SharePoint site and each document library.

**Get your Site ID:**
In a browser (signed into Microsoft 365), visit:
```
https://your-tenant.sharepoint.com/sites/your-site/_api/site/id
```
The GUID in the response is your `SHAREPOINT_SITE_ID`.

Alternatively, use Microsoft Graph Explorer (`aka.ms/ge`) and call:
```
GET https://graph.microsoft.com/v1.0/sites/your-tenant.sharepoint.com:/sites/your-site
```

**Get List IDs** — for each library below, call:
```
GET https://graph.microsoft.com/v1.0/sites/{siteId}/lists
```
Note the `id` value for each list you will use.

---

### Step 3 — Create the Required SharePoint Lists

EduAssist expects up to four SharePoint lists. Only the ones you configure are used — each degrades gracefully if absent.

#### 3a. Curriculum Library (`SHAREPOINT_CURRICULUM_LIST_ID`)
Document library containing teacher-facing curriculum materials.

Required columns on list items:
| Column | Type | Purpose |
|---|---|---|
| `Title` | Single line of text | Document name shown in audit log |
| `GradeLevel` | Choice or text | e.g. `5`, `K`, `9-12` |
| `Subject` | Choice or text | e.g. `Math`, `ELA`, `Science` |
| `Standard` | Single line of text | e.g. `5.NBT.A.1` (optional) |

Upload your district's scope and sequence documents, pacing guides, and standards frameworks here. EduAssist fetches up to 5 matching items per lesson plan request, downloads the file text, and uses it as grounding context for Claude.

#### 3b. Student Content List (`SHAREPOINT_STUDENT_CONTENT_LIST_ID`)
List of curriculum-aligned content metadata used to ground the student AI companion.

Required columns:
| Column | Type | Purpose |
|---|---|---|
| `Title` | Single line of text | Content title |
| `GradeLevel` | Choice or text | Grade filter |
| `Subject` | Choice or text | Subject filter |
| `Standard` | Single line of text | Standards alignment |

#### 3c. Official Documents Library (`SHAREPOINT_OFFICIAL_DOCS_LIST_ID`)
Document library where EduAssist saves AI-generated lesson plans and parent letters.

Required columns:
| Column | Type | Purpose |
|---|---|---|
| `Title` | Single line of text | Auto-populated by EduAssist |
| `Grade` | Single line of text | Auto-populated |
| `Subject` | Single line of text | Auto-populated |
| `School` | Single line of text | Auto-populated |
| `DocumentType` | Choice | `LessonPlan` or `ParentLetter` |
| `ApprovalStatus` | Choice | `PendingApproval`, `Approved`, `Rejected` |

Connect a Power Automate flow to this library to handle your district's document approval process.

#### 3d. Policies Library (`SHAREPOINT_POLICIES_LIST_ID`) — optional
List of district policy document titles. If configured, policy titles are injected into the student companion's system prompt so the AI operates within district-defined boundaries.

Required columns: `Title` only.

---

### Step 4 — Store Secrets in Firebase Secret Manager

From the command line in the `EduAssistall/` directory:

```bash
firebase functions:secrets:set AZURE_TENANT_ID
# paste your Directory (tenant) ID when prompted

firebase functions:secrets:set AZURE_CLIENT_ID
# paste your Application (client) ID

firebase functions:secrets:set AZURE_CLIENT_SECRET
# paste your client secret value

firebase functions:secrets:set SHAREPOINT_SITE_ID
# paste your SharePoint site GUID

firebase functions:secrets:set SHAREPOINT_CURRICULUM_LIST_ID
# paste the curriculum library list ID

firebase functions:secrets:set SHAREPOINT_OFFICIAL_DOCS_LIST_ID
# paste the official documents library list ID

# Optional — add these only if you are using those lists:
firebase functions:secrets:set SHAREPOINT_STUDENT_CONTENT_LIST_ID
firebase functions:secrets:set SHAREPOINT_POLICIES_LIST_ID
```

---

### Step 5 — Deploy Cloud Functions

```bash
cd EduAssistall
firebase deploy --only functions
```

The functions that use SharePoint secrets are:
- `generateLessonPlan` — reads curriculum, writes output to OfficialDocuments
- `generateParentLetter` — writes output to OfficialDocuments
- `askCompanion` — reads StudentContent and Policies for grounding
- `sharepointWebhookReceiver` — receives change notifications from SharePoint
- `registerSharePointWebhooks` — admin-callable, registers the webhooks
- `renewSharePointWebhooks` — scheduled, keeps webhook subscriptions alive

---

### Step 6 — Register SharePoint Webhooks

Webhooks let SharePoint notify EduAssist in real time when curriculum documents change, so the grounding cache is invalidated and the next AI call sees the updated content.

After deploying functions, call `registerSharePointWebhooks` from the app as an admin user, passing the webhook receiver URL:

```
https://us-central1-eduassist-b1f49.cloudfunctions.net/sharepointWebhookReceiver
```

SharePoint webhook subscriptions expire after approximately 3 days. The `renewSharePointWebhooks` scheduled function runs automatically to renew them.

---

### Step 7 — Verify the Integration

1. Open the app as a teacher and tap the menu → **Generate Lesson Plan**.
2. Select a grade, subject, and enter a topic that matches documents in your Curriculum Library.
3. Tap **Generate**. The plan should appear within 10–15 seconds.
4. Check your SharePoint OfficialDocuments library — the plan should appear as a new file with `ApprovalStatus: PendingApproval`.
5. Check the Xcode console (or Firebase Functions logs) for `[generateLessonPlan]` entries confirming which curriculum items were used as grounding.

If SharePoint is not configured, the function degrades gracefully — it generates a lesson plan without district grounding and skips the SharePoint write. No error is shown to the teacher.

---

## Security Notes

- The Azure client secret is stored exclusively in **Firebase Secret Manager** — it is never in the app binary, never in source code, and never visible to any client device.
- All Graph API calls are server-side only (Cloud Functions). Students and teachers have no direct access to SharePoint.
- EduAssist requests only the minimum Graph API permissions needed. `Sites.Read.All` covers curriculum reads; `Sites.ReadWrite.All` is required only for writing generated documents back.
- The client secret should be rotated annually. Update it in Firebase Secret Manager and redeploy functions — no app update required.

---

## Support

For setup assistance, contact the EduAssist implementation team. When reporting issues, include the output of:
```bash
firebase functions:log --only generateLessonPlan
```
