# EduAssist — App Store Submission Reference

Use this document when filling in App Store Connect. All fields marked **[REQUIRED]** must be completed before submission.

---

## App Information

| Field | Value |
|---|---|
| App Name | EduAssist |
| Bundle ID | clarkdjcr.EduAssistall |
| Version | 1.0 |
| Build | 1 |
| Primary Language | English (U.S.) |
| Category (Primary) | Education |
| Category (Secondary) | Productivity |
| Content Rights | Does not contain, show, or access third-party copyrighted material |

---

## App Store Description

### Subtitle (30 chars max)
```
AI Learning Companion for K–12
```

### Description (4,000 chars max)
```
EduAssist is an AI-powered study companion built for K–12 students, with
privacy and educator oversight at its core.

STUDENTS
Ask the AI companion anything about your lessons, homework, or topics you're
curious about — and get thoughtful, grade-appropriate guidance that teaches
you how to think, not just what to think. Choose from four learning modes:
Guided Discovery, Co-Creation, Reflective Coaching, or Silent Support.

Set personal learning goals, track your progress through teacher-assigned
learning paths, and review your AI Learning Journal — an auto-generated
summary of every study session.

TEACHERS
Monitor every student's active session in real time. Send a hint directly
into a student's conversation. Pause a student's AI session with one tap.
Assign learning paths, curate content from Khan Academy and edX, and
receive a daily digest of student progress and safety alerts.

PARENTS & GUARDIANS
Link to your child's account to follow their learning progress, view
completed goals, and stay informed — all with your child's knowledge and
consent.

BUILT FOR SCHOOLS
- COPPA & FERPA compliant — student data is never used for advertising
- All AI processing uses anonymised context — no name or email is sent to
  the AI model
- Distress detection automatically alerts school counsellors
- Content moderation blocks harmful topics before they reach the AI
- District administrators control data retention periods
- Full data export and account deletion available at any time

ACCESSIBILITY
Dyslexia-friendly font, high-contrast mode, larger text, and reduced-motion
options are available in Settings.
```

### Keywords (100 chars max, comma-separated)
```
AI tutor,K-12,homework help,learning,education,students,teachers,study,COPPA,classroom
```

### Support URL **[REQUIRED — must be live before submission]**
```
https://[YOUR DOMAIN]/support
```

### Marketing URL (optional)
```
https://[YOUR DOMAIN]
```

### Privacy Policy URL **[REQUIRED — must be live before submission]**
```
https://[YOUR DOMAIN]/privacy
```

> Host the content from `docs/PRIVACY_POLICY.md` at this URL. It must be
> publicly accessible without a login.

---

## Age Rating

Complete the **Age Rating** questionnaire in App Store Connect with the following answers:

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use | None |
| Gambling | None |
| Contests | None |
| **Unrestricted Web Access** | **No** — AI responses are filtered and do not expose a browser |

**Resulting Rating: 4+**

> Note: Apple may apply a higher age rating if reviewers determine the AI
> chat constitutes "unrestricted web access." If this happens, select
> **9+** and add the note: "AI responses are safety-filtered and limited
> to educational content."

---

## App Privacy (Nutrition Labels)

In App Store Connect → App Privacy, declare the following. For each data type, the **Linked to Identity** column means it can be traced back to the user's account.

### Data Used to Track You
**None.** Select "No" when asked if the app tracks users.

### Data Linked to You

| Data Type | Category | Used For | Linked to Identity |
|---|---|---|---|
| Name | Contact Info | App Functionality | Yes |
| Email Address | Contact Info | App Functionality, Account | Yes |
| User ID | Identifiers | App Functionality | Yes |
| Learning history & goals | Usage Data | App Functionality | Yes |
| AI conversation messages | User Content | App Functionality | Yes |
| Push token (FCM) | Device ID | App Functionality (notifications) | Yes |

### Data Not Linked to You

| Data Type | Category | Used For |
|---|---|---|
| Crash logs | Diagnostics | App Functionality (Firebase Crashlytics if added) |
| Performance metrics | Diagnostics | App Functionality |

### Data Not Collected
Select **Not Collected** for:
- Health & Fitness
- Financial Info
- Location
- Contacts
- Photos or Videos
- Audio Data
- Browsing History
- Search History
- Sensitive Info

---

## Export Compliance

| Question | Answer |
|---|---|
| Does the app use encryption? | **Yes** — standard HTTPS/TLS only |
| Is the encryption exempt from US export regulations? | **Yes** — uses only standard encryption (ATS/TLS 1.2+). Select "Yes, it uses only exempt encryption (HTTPS, TLS, SSL)" |

> This exempts you from filing an Annual Self-Classification Report (ASCR).
> In Info.plist, add: `ITSAppUsesNonExemptEncryption = NO`

---

## App Review Information

### Demo Account **[REQUIRED]**
Provide a test account for each role so reviewers can test all flows.

| Role | Email | Password |
|---|---|---|
| Student | [CREATE BEFORE SUBMISSION] | [SET BEFORE SUBMISSION] |
| Teacher | [CREATE BEFORE SUBMISSION] | [SET BEFORE SUBMISSION] |
| Parent | [CREATE BEFORE SUBMISSION] | [SET BEFORE SUBMISSION] |

The teacher account should already have the student linked and a learning path assigned so reviewers can see the full teacher dashboard without setup steps.

### Notes for Reviewer
```
EduAssist is a K–12 AI learning companion. Three user roles are available:
Student, Teacher, and Parent/Guardian.

Demo accounts are provided above for each role. Sign in with the Student
account to try the AI Companion (AI chat tab). Sign in with the Teacher
account to see the educator dashboard, student monitoring, and learning
path management. Sign in with the Parent account to see the linked-child
overview.

The AI companion requires a network connection and calls a Firebase Cloud
Function which in turn calls the Claude AI API. Please ensure the review
device has internet access.

Note: The app uses COPPA-compliant data practices. Student data is never
used for advertising. The AI model receives only anonymised context
(grade level, subject, mode) — no name or email.
```

---

## Info.plist Additions Required Before Submission

Add the following keys to `EduAssistall/Info.plist` if not already present:

```xml
<!-- Export compliance — standard TLS only, no non-exempt encryption -->
<key>ITSAppUsesNonExemptEncryption</key>
<false/>

<!-- Required if you request notification permission -->
<key>NSUserNotificationsUsageDescription</key>
<string>EduAssist sends you notifications when your teacher assigns new content or sends you a message.</string>
```

---

## Screenshots Required

Apple requires screenshots for every device size you support. Minimum required sets:

| Device | Size | Required |
|---|---|---|
| iPhone 6.9" (16 Pro Max) | 1320 × 2868 px | Yes |
| iPhone 6.7" (15 Plus) | 1290 × 2796 px | Yes |
| iPad Pro 13" (M4) | 2064 × 2752 px | Yes (iPad primary target) |
| iPad Pro 11" (M4) | 1668 × 2420 px | Recommended |

Suggested screens to capture:
1. AI Companion chat with a multi-turn conversation showing formatted responses
2. Student Dashboard with learning path progress
3. Learning Goals list
4. Teacher Monitor dashboard showing active students
5. Mode Picker sheet (the four learning modes)

---

## Pre-Submission Checklist

- [ ] Privacy Policy hosted at a public URL
- [ ] Support URL live and responding
- [ ] Demo accounts created for all three roles with content pre-populated
- [ ] `ITSAppUsesNonExemptEncryption = NO` in Info.plist
- [ ] `NSUserNotificationsUsageDescription` in Info.plist
- [ ] Screenshots captured for all required device sizes
- [ ] App icon provided in all required sizes (handled by asset catalog)
- [ ] Age Rating questionnaire completed (result: 4+)
- [ ] App Privacy nutrition labels filled in
- [ ] Export compliance answered
- [ ] Firebase `eduassist-b1f49-backups` GCS bucket created (for DR backup function)
- [ ] ANTHROPIC_API_KEY secret set in Firebase Secret Manager
- [ ] Firestore rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Cloud Functions deployed (`firebase deploy --only functions`)
