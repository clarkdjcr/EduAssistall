# EduAssist Privacy Policy

**Effective Date:** [INSERT DATE BEFORE SUBMISSION]
**Last Updated:** [INSERT DATE BEFORE SUBMISSION]

---

## 1. Who We Are

EduAssist ("we", "us", or "our") is an AI-powered learning companion application for K–12 students, operated by **[YOUR LEGAL ENTITY NAME]** ("Company"), located at **[YOUR ADDRESS]**. Contact: **[YOUR EMAIL]**

---

## 2. Scope of This Policy

This policy applies to the EduAssist iOS/iPadOS application and all related services. It explains what personal information we collect, why we collect it, how it is used and protected, and the rights available to users and their parents or guardians.

Because EduAssist is used by students, including children under the age of 13, this policy is written to comply with:

- The **Children's Online Privacy Protection Act (COPPA)**, 15 U.S.C. § 6501–6506
- The **Family Educational Rights and Privacy Act (FERPA)**, 20 U.S.C. § 1232g
- The **California Consumer Privacy Act (CCPA/CPRA)** where applicable
- Apple App Store guidelines for apps directed at children

---

## 3. Information We Collect

### 3.1 Account Information
- **Email address** — used for authentication and account recovery
- **Display name** — shown within the app to educators and linked adults
- **Role** (student, teacher, or parent/guardian) — controls which features are available
- **School district ID** — links a student to their institution's configuration

### 3.2 Educational Records
- **Learning profile** — grade level, subject interests, preferred learning style (VARK)
- **Learning path progress** — which content items have been viewed or completed
- **Learning goals** — student-set objectives and their completion status
- **Learning journal entries** — AI-generated summaries of study sessions, stored per student

### 3.3 AI Companion Interactions
- **Conversation messages** — the text of questions asked to the AI companion and its replies, stored in our database to provide conversation continuity across sessions
- **Interaction mode** — the teaching style selected (e.g. Guided Discovery, Co-Creation)
- **Safety classification records** — anonymised records of content moderation decisions (no personally identifiable content is retained in these records)

### 3.4 Usage and Session Data
- **Active session indicators** — whether a student currently has the companion open (visible to linked educators only; cleared when the app is closed)
- **Session flags** — automated alerts generated when the AI detects signs of frustration or distress (visible to linked educators only)
- **Audit log events** — sign-in, sign-out, data export, and account deletion timestamps

### 3.5 Device Information
- **FCM token** — a Firebase Cloud Messaging token used to deliver push notifications; rotated automatically and never used for advertising

### 3.6 Information We Do NOT Collect
- Precise geolocation
- Contacts, photos, camera, or microphone access
- Biometric identifiers
- Advertising identifiers (IDFA)
- Health or financial data

---

## 4. How We Use Information

| Purpose | Legal Basis |
|---|---|
| Providing the AI companion and learning features | Performance of service |
| Showing educators the progress of students in their class | Legitimate educational interest (FERPA school-official exception) |
| Allowing parents/guardians to monitor a linked child's progress | Parental consent / COPPA compliance |
| Sending push notifications about new recommendations or messages | Consent (user grants notification permission) |
| Sending educators a daily digest of student activity | Performance of service |
| Safety monitoring (distress detection, content moderation) | Legitimate interest / child safety |
| Improving service reliability and performance | Legitimate interest |
| Complying with legal obligations | Legal obligation |

We do **not** use student data for advertising, do not sell personal information, and do not build advertising profiles.

---

## 5. AI Processing and Third-Party Services

EduAssist uses the following sub-processors. Each is bound by a data processing agreement.

| Provider | Purpose | Data Sent | Privacy Policy |
|---|---|---|---|
| **Google Firebase** (Firebase Auth, Firestore, Cloud Functions, FCM) | Authentication, database, serverless compute, push notifications | Account data, messages, progress data | [firebase.google.com/support/privacy](https://firebase.google.com/support/privacy) |
| **Anthropic** (Claude API) | AI companion responses | The text of the student's message, a summary context prompt (grade level, subject, interaction mode). **No name, email, or school is sent to Anthropic.** | [anthropic.com/privacy](https://www.anthropic.com/privacy) |
| **Twilio SendGrid** | Educator daily digest emails; critical safety alert emails to school counsellors | Educator email address, anonymised student alert summary | [twilio.com/legal/privacy](https://www.twilio.com/legal/privacy) |

All data is stored in **Google Cloud us-central1 (Iowa, USA)**. No data is transferred outside the United States.

---

## 6. Children's Privacy (COPPA)

EduAssist is designed for use in school settings and may be used by children under 13. We comply with COPPA as follows:

**School-Operator Model:** EduAssist operates under the school-operator exception to COPPA (16 C.F.R. § 312.4(c)(4)). Schools and school districts act as agents of parents when consenting to the collection of student data for educational purposes. By deploying EduAssist to students, a school or district represents that it has obtained any necessary parental consents.

**No behavioural advertising:** Student data is never used for advertising or commercial purposes unrelated to the educational service.

**Parental access:** Parents who have linked their account to a student may request access to, correction of, or deletion of their child's data at any time through the app (Settings → Privacy & Data) or by contacting us directly.

**Deletion:** Parents or students may delete their account and all associated data at any time. Audit log entries required for legal compliance are retained for 2 years after account deletion; all other data is deleted within 30 days.

---

## 7. Data Retention

| Data Category | Default Retention | Notes |
|---|---|---|
| Conversation messages | 90 days | Configurable by district administrator (30–365 days) |
| Session flags | 30 days | Configurable by district administrator (7–90 days) |
| Safety classifications | 90 days | Configurable by district administrator (30–365 days) |
| Audit logs | 365 days | Configurable by district administrator (180–730 days) |
| Critical safety events | Permanent | Required for safeguarding compliance |
| Learning goals & progress | Until account deletion | Core educational record |
| Account data | Until account deletion | |

---

## 8. Data Security

- All data is transmitted over TLS 1.2 or higher.
- Firestore security rules enforce strict role-based access: students cannot read other students' data; parents can only access linked children; teachers can only access students in their class.
- The Anthropic API key is stored in Firebase Secret Manager and is never embedded in the iOS app or transmitted to user devices.
- Parent–child account linking requires mutual confirmation: the child must accept the link from their own account before any data is shared, and link invitations expire after 7 days.

---

## 9. Your Rights

Depending on your jurisdiction, you or your child's parent/guardian may have the right to:

- **Access** a copy of the personal data we hold (available via Settings → Privacy & Data → Export My Data)
- **Correct** inaccurate data (contact us directly)
- **Delete** your account and all associated data (Settings → Privacy & Data → Delete My Account)
- **Withdraw consent** for optional AI training data use at any time (Settings → Privacy & Data)
- **Restrict or object** to certain processing (contact us)

To exercise any right not available in-app, contact us at **[YOUR EMAIL]**. We will respond within 30 days.

---

## 10. Changes to This Policy

We will notify users of material changes by displaying a notice within the app at least 14 days before the change takes effect. For changes that materially affect how children's data is used, we will obtain fresh consent where required by law.

---

## 11. Contact Us

**[YOUR LEGAL ENTITY NAME]**
**[YOUR ADDRESS]**
Email: **[YOUR EMAIL]**
