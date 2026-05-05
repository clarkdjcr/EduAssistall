#!/usr/bin/env node
/**
 * Uploads sample district policy documents to the SharePoint Policies library.
 * Uses app-only auth — service principal has site owner access from provisioning.
 *
 * Usage:
 *   node scripts/upload-policy-docs.js
 */

const TENANT_ID     = process.env.AZURE_TENANT_ID;
const CLIENT_ID     = process.env.AZURE_CLIENT_ID;
const CLIENT_SECRET = process.env.AZURE_CLIENT_SECRET;
const SITE_ID       = process.env.SHAREPOINT_SITE_ID;
const LIST_ID       = process.env.SHAREPOINT_POLICIES_LIST_ID;

const POLICY_DOCS = [
  {
    filename: "AcceptableUsePolicy.txt",
    metadata: { School: "All" },
    content: `STUDENT ACCEPTABLE USE POLICY
EduAssist AI Companion — District Guidelines

EFFECTIVE DATE: ${new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}

PURPOSE
This policy governs student use of the EduAssist AI Companion. It supplements the district's
broader Acceptable Use Policy for technology.

PERMITTED USES
Students may use the AI Companion for:
• Asking questions about assigned curriculum content
• Getting step-by-step explanations of academic concepts
• Reviewing practice problems with guided feedback
• Exploring career paths and academic options
• Getting help understanding assignment instructions

PROHIBITED USES
Students may NOT use the AI Companion to:
• Complete homework or assessments on their behalf
• Obtain direct answers to quiz or test questions
• Discuss or request information about violence, weapons, drugs, or sexual content
• Share personal information (full name, address, phone number, email)
• Attempt to bypass or manipulate the AI's safety guidelines
• Use the system for purposes unrelated to their education

PRIVACY
• All conversations are logged and may be reviewed by teachers and administrators
• Personal information is automatically detected and removed from conversations
• Parents and guardians may request a copy of their child's conversation history

DISTRESS & SAFETY
If a student expresses distress, self-harm ideation, or reports being in danger, the AI
Companion will provide crisis resources and automatically alert school counselors.
Students in crisis should speak to a trusted adult immediately.

CONSEQUENCES
Violation of this policy may result in restricted access to the AI Companion and
disciplinary action consistent with the district's student code of conduct.

ACKNOWLEDGMENT
Students and families are expected to review this policy annually. Continued use of
the EduAssist AI Companion constitutes acceptance of these terms.`,
  },
  {
    filename: "StudentPrivacyNotice.txt",
    metadata: { School: "All" },
    content: `STUDENT PRIVACY NOTICE
EduAssist AI Companion — How We Handle Student Data

EFFECTIVE DATE: ${new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}

OVERVIEW
This notice explains what data the EduAssist AI Companion collects, how it is used,
and the rights students and families have under FERPA, COPPA, and applicable state law.

WHAT WE COLLECT
• Conversation messages (after automatic PII redaction)
• Learning profile: grade level, learning style, subject interests
• Progress data: completed content items, quiz results, milestones
• Session metadata: session start/end times, interaction counts

WHAT WE DO NOT COLLECT
• Raw personal information in messages (automatically redacted before storage)
• Student photographs or biometric data
• Financial information
• Health or medical records (except voluntary disclosures in conversation, which trigger safety protocols)

HOW WE USE DATA
• To personalize AI responses to the student's grade level and learning style
• To track progress across learning paths
• To alert educators when safety concerns arise in conversations
• To generate progress reports for teachers and parents
• For aggregate, de-identified analysis to improve the system

DATA SHARING
Student data is shared only with:
• The student's assigned teachers and school administrators
• The student's parent or guardian (upon request or as required by law)
• School counselors (in the event of a safety alert)
• Authorized district IT staff for support purposes
We do not sell, rent, or share student data with third parties for advertising or commercial purposes.

DATA RETENTION
Conversation history: 1 year from the last message, then automatically deleted.
Learning profiles and progress data: retained for the duration of enrollment, then deleted within 90 days of departure.

PARENT & STUDENT RIGHTS
Under FERPA, parents and eligible students have the right to:
• Inspect and review education records
• Request correction of inaccurate records
• Request deletion of data (subject to legal retention requirements)
To exercise these rights, contact the school's designated privacy officer or use the
Data & Privacy section in the EduAssist app settings.

CONTACT
Questions about this notice should be directed to the district's Data Privacy Officer.`,
  },
  {
    filename: "AITransparencyNotice.txt",
    metadata: { School: "All" },
    content: `AI TRANSPARENCY NOTICE
EduAssist AI Companion — How the AI Works

EFFECTIVE DATE: ${new Date().toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" })}

WHAT POWERS THE AI
The EduAssist AI Companion is powered by Claude, an AI assistant made by Anthropic.
Responses are generated by a large language model and are not written by a human in real time.

HOW RESPONSES ARE SHAPED
Every AI response is shaped by:
• The student's grade level and learning style (from their learning profile)
• The student's active learning path and current goals
• District curriculum materials matched to the student's grade and subject
• District-specific topic restrictions set by administrators
• Interaction mode settings configured by the teacher

SAFETY MEASURES
Before any student message reaches the AI, it is checked for:
• Harmful content (violence, weapons, drugs, sexual content) — blocked before the AI sees it
• Personal information — automatically removed and never sent to the AI
• Distress signals — if detected, the AI does not respond; a human counselor is alerted instead

After the AI generates a response, it is checked again before being shown to the student.

LIMITATIONS
The AI may sometimes:
• Give incomplete or imprecise answers
• Misunderstand ambiguous questions
• Reflect biases present in its training data
• Be unavailable during high-demand periods

Students should always verify important information with their teacher.

NO AUTONOMOUS DECISION-MAKING
The AI Companion does not make autonomous decisions about grades, disciplinary action,
academic placement, or any other high-stakes student outcome. All such decisions remain
with qualified human educators.

HUMAN OVERSIGHT
• Teachers can review all student conversations
• Teachers can pause a student's AI access at any time
• Educators can configure topic restrictions and response styles
• Administrators can audit all AI-generated outputs`,
  },
];

async function getToken() {
  const res = await fetch(
    `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`,
    {
      method: "POST",
      body: new URLSearchParams({
        grant_type: "client_credentials", client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET, scope: "https://graph.microsoft.com/.default",
      }),
    }
  );
  const data = await res.json();
  if (!data.access_token) throw new Error(`Token error: ${JSON.stringify(data)}`);
  return data.access_token;
}

async function graph(token, method, path, body, contentType) {
  const res = await fetch(`https://graph.microsoft.com/v1.0${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, "Content-Type": contentType || "application/json" },
    body: body ? (contentType ? body : JSON.stringify(body)) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Graph ${method} ${path} → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

async function main() {
  if (!TENANT_ID || !CLIENT_ID || !CLIENT_SECRET || !SITE_ID || !LIST_ID) {
    console.error("Missing env vars. Need AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, SHAREPOINT_SITE_ID, SHAREPOINT_POLICIES_LIST_ID");
    process.exit(1);
  }

  console.log("Authenticating...");
  const token = await getToken();

  console.log("Fetching Policies drive...");
  const drive = await graph(token, "GET", `/sites/${SITE_ID}/lists/${LIST_ID}/drive`);
  const driveId = drive.id;
  console.log(`  Drive ID: ${driveId}\n`);

  for (const doc of POLICY_DOCS) {
    process.stdout.write(`Uploading ${doc.filename} ... `);
    const uploaded = await graph(
      token, "PUT",
      `/drives/${driveId}/root:/${doc.filename}:/content`,
      Buffer.from(doc.content, "utf-8"), "text/plain"
    );
    const driveItem = await graph(token, "GET", `/drives/${driveId}/items/${uploaded.id}?$select=id,sharepointIds`);
    const listItemId = driveItem.sharepointIds?.listItemId;
    if (listItemId) {
      await graph(token, "PATCH", `/sites/${SITE_ID}/lists/${LIST_ID}/items/${listItemId}/fields`, {
        Title:  doc.filename.replace(".txt", "").replace(/([A-Z])/g, " $1").trim(),
        School: doc.metadata.School,
      });
    }
    console.log(`done (item ${listItemId ?? "unknown"})`);
  }

  console.log(`\n=== ${POLICY_DOCS.length} policy documents uploaded to Policies library ===`);
  console.log("View at: https://5h1yp7.sharepoint.com/sites/EduAssist/Policies");
}

main().catch(err => { console.error("\nFailed:", err.message); process.exit(1); });
