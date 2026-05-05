# EduAssist Functional Requirements

**Design principle:** Deterministic (non-AI) features handle most operations (cheap, predictable). AI (Copilot / Azure OpenAI) is used only for judgment tasks. Overall system cost stays bounded and explainable for districts.

**Assumed licensing baseline:** Microsoft A3 or A5 with optional Copilot for Microsoft 365 add-on.

---

## 2.1 Curriculum & Content Management

### Deterministic

| ID | Requirement |
|---|---|
| FR-C1 | Retrieve curriculum, policies, and resources from SharePoint libraries via Microsoft Graph. |
| FR-C2 | Filter content by grade, subject, standard, school, and term using metadata. |
| FR-C3 | Enforce SharePoint permissions and Purview labels for all content access. *(See also FR-G2 — single enforcement implementation, dual reference.)* |
| FR-C4 | Store all "official" generated documents (lesson plans, letters, reports) back into SharePoint with metadata. A Power Automate approval flow must complete before the write; no AI output may be written to an official library without human approval. |

### AI (judgment)

| ID | Requirement | Licensing |
|---|---|---|
| FR-C5 | Generate lesson plans grounded in selected SharePoint curriculum. | Copilot for M365 or Azure OpenAI deployment |
| FR-C6 | Create differentiated versions (e.g., below/at/above grade level). | Copilot for M365 or Azure OpenAI deployment |
| FR-C7 | Rewrite content for parents or students (tone, reading level, language). | Copilot for M365 or Azure OpenAI deployment |

---

## 2.2 Forms, Incidents, and Documentation

### Deterministic

| ID | Requirement |
|---|---|
| FR-F1 | Create and manage SharePoint lists and modern forms for: incident reports, parent communication logs, and requests (IT, facilities, academic). |
| FR-F2 | Apply validation rules, required fields, and conditional logic (no AI). |
| FR-F3 | Trigger Power Automate flows on form submission (routing, notifications). |
| FR-F4 | Populate Word/PDF templates with known structured fields (student, date, school, incident type, etc.). |
| FR-F5 | Store final documents (PDF/Word) in SharePoint libraries with proper metadata and retention. |

### AI (judgment)

| ID | Requirement | Licensing |
|---|---|---|
| FR-F6 | Summarize incident narratives into concise, leadership-ready summaries. | Copilot for M365 or Azure OpenAI deployment |
| FR-F7 | Generate parent-friendly explanations of incidents or interventions. | Copilot for M365 or Azure OpenAI deployment |
| FR-F8 | Create weekly/monthly narrative summaries of incidents by pattern (grade, school, type). | Copilot for M365 or Azure OpenAI deployment |

---

## 2.3 Teacher Productivity (Planning, Communication, Reporting)

### Deterministic

| ID | Requirement |
|---|---|
| FR-T1 | Manage session state, drafts, and UI state in Firestore (fast, real-time). Drafts not promoted to SharePoint within 30 days are surfaced to the user as "abandoned drafts" and purged after a 7-day grace period. |
| FR-T2 | Provide deterministic templates for: lesson structures, parent communication formats, and progress report shells. |
| FR-T3 | Save "approved" outputs to SharePoint (via FR-C4 approval flow); keep drafts in Firestore. |
| FR-T4 | Enforce role-based access (teacher vs admin vs student) via Azure AD / Entra ID. |

### AI (judgment)

| ID | Requirement | Licensing |
|---|---|---|
| FR-T5 | Generate first-draft lesson plans from curriculum. | Copilot for M365 or Azure OpenAI deployment |
| FR-T6 | Draft parent emails/letters from structured data (grades, incidents, progress). | Copilot for M365 or Azure OpenAI deployment |
| FR-T7 | Summarize student progress across multiple artifacts (assignments, notes, incidents). | Copilot for M365 or Azure OpenAI deployment |

---

## 2.4 Student Experience

### Deterministic

| ID | Requirement |
|---|---|
| FR-S1 | Restrict student content sources to student-safe SharePoint libraries. |
| FR-S2 | Log student sessions and interactions in Firestore (non-record analytics). |
| FR-S3 | Enforce age and role restrictions for AI features per the table below. No AI feature in FR-S4–S6 may be exposed to a user under the stated minimum age without verified parental consent on file. |

**FR-S3 Age Gate Table**

| AI Feature | Minimum Age | Parental Consent Required |
|---|---|---|
| FR-S4 Grounded Q&A | 8 | No (district consent via FERPA) |
| FR-S5 Step-by-step explanations / practice questions | 8 | No (district consent via FERPA) |
| FR-S6 Content rephrasing | 8 | No (district consent via FERPA) |
| Any feature that retains student conversation history | 13 | Yes (COPPA) |
| Any feature that personalizes based on inferred profile | 13 | Yes (COPPA) |

### AI (judgment) — with mandatory safety pipeline

All three AI student features (FR-S4, FR-S5, FR-S6) must route through the safety pipeline defined in FR-S7 before any AI call is made and before any AI output is returned to the student. The pipeline is not optional and may not be bypassed by feature flags or configuration.

| ID | Requirement | Licensing |
|---|---|---|
| FR-S4 | Explain concepts using district materials (grounded Q&A). | Copilot for M365 or Azure OpenAI deployment |
| FR-S5 | Provide step-by-step explanations and practice questions. | Copilot for M365 or Azure OpenAI deployment |
| FR-S6 | Rephrase content at different reading levels. | Copilot for M365 or Azure OpenAI deployment |

### Safety Pipeline (FR-S7) — applies to all student AI features

FR-S7 defines the mandatory synchronous pipeline that wraps every student-facing AI call. Each stage must complete before the next begins. Total pipeline latency target: < 200 ms excluding the AI model call.

| Stage | ID | Behavior on Trigger |
|---|---|---|
| **Input classifier** | FR-S7a | Regex/rule-based. Categories: violence, weapons, drugs, sexual → reject with safe refusal message. Bullying, emotional distress, alcohol → pass through but flag for FR-S7c evaluation. Latency target < 100 ms. Write classification event to `safetyClassifications/{autoId}` regardless of verdict. |
| **PII detection & redaction** | FR-S7b | Detect and redact phone numbers, email addresses, SSNs, payment card numbers, physical addresses, full names, URLs, and ZIP codes to `[REDACTED:<type>]` before the student input is sent to the AI model or used in a SharePoint grounding query. Redacted form is what reaches the model; original is never logged. |
| **Distress detection** | FR-S7c | Evaluate inputs flagged by FR-S7a as emotional distress. On positive match: return an empathetic, non-AI canned response; send counselor alert via configured notification channel; write a tamper-evident record to `criticalSafetyEvents/{eventId}` (append-only, never deleted). Do not call the AI model. |
| **Output classifier** | FR-S7d | After AI model returns a response, classify it before delivery to student. Block and substitute a safe fallback if the output contains: harmful instructions, violence instructions, self-harm encouragement, sexual content, or drug facilitation language. Write classification event to `safetyClassifications/{autoId}`. |
| **Frustration detection** | FR-S7e | Fire-and-forget after output delivery. Detect repeated rephrasing of the same question, negative sentiment, or escalating short responses. Write a flag to `sessionFlags/{studentId}/flags/{autoId}` for educator review. Does not block or delay the student response. |

All `safetyClassifications` events must include: `verdict`, `reason`, `latencyMs`, `classifierVersion`, `studentId` (hashed), `featureId` (e.g. "FR-S4"), and `timestamp`.

---

## 2.5 Governance, Safety, and Cost Control

### Deterministic

| ID | Requirement |
|---|---|
| FR-G1 | All access controlled via Azure AD / Entra ID roles and groups. |
| FR-G2 | Respect SharePoint permissions and Purview labels for every content call. *(Single implementation shared with FR-C3.)* |
| FR-G3 | Implement per-user, per-school, and per-feature AI usage quotas. Enforcement must occur at the API gateway layer (Azure API Management or equivalent) — not solely in application-layer counters — to prevent race conditions under concurrent requests. |
| FR-G4 | Cache AI outputs (lesson plans, summaries, letters) and reuse when the grounding source document has not changed. Cache entries must be keyed on the source SharePoint document ID and version. A SharePoint webhook on document modification must invalidate all cache entries referencing that document ID within 60 seconds of the modification event. |
| FR-G5 | Provide admin dashboards for AI usage, cost estimates, and feature adoption. |

### Audit Logging

| ID | Requirement |
|---|---|
| FR-G6 | Every AI generation event — across all roles (student, teacher, admin) — must produce an append-only audit record in `aiAuditLog/{eventId}`. Records may never be updated or deleted. Each record must include: `featureId`, `userId` (hashed), `schoolId`, `timestamp`, `groundingSourceIds` (array of SharePoint document IDs used), `inputTokenCount`, `outputTokenCount`, `cacheHit` (boolean), `safetyPipelineApplied` (boolean, always true for student features), `approvalWorkflowId` (for teacher outputs promoted to SharePoint), and `modelVersion`. This log is the authoritative record for district compliance reviews and e-discovery requests. |

---

## Cross-Cutting Notes

- **FR-C4 and FR-G6 together** enforce the human-in-the-loop + auditability requirement for official document creation. Neither is sufficient alone.
- **FR-S7 and FR-G6 together** enforce student safety and provide the audit trail to demonstrate compliance. The `safetyClassifications` collection is the operational record; `aiAuditLog` is the compliance record.
- **Firestore as session store (FR-T1):** Retained deliberately for real-time draft sync latency. Azure Cosmos DB is the Microsoft-native alternative if the district requires single-cloud architecture — evaluate at district onboarding.
