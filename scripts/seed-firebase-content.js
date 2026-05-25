#!/usr/bin/env node
/**
 * Seeds sample grounding content and policy documents to Firebase Storage + Firestore
 * for districts using the Firebase document backend (documentBackend: "firebase").
 *
 * Replaces SharePoint as the document store for districts without M365 and homeschool users.
 *
 * Prerequisites:
 *   gcloud auth application-default login
 *   cd EduAssistall/functions && npm install
 *
 * Usage:
 *   FIREBASE_PROJECT=eduassist-b1f49 node scripts/seed-firebase-content.js
 *
 * Optional env vars:
 *   DISTRICT_ID   — Firestore districtId to scope policies (default: "all")
 *   STORAGE_BUCKET — Override default bucket (default: {PROJECT}.appspot.com)
 */

const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getFirestore, FieldValue }      = require("firebase-admin/firestore");
const { getStorage }                    = require("firebase-admin/storage");

const PROJECT_ID    = process.env.FIREBASE_PROJECT || "eduassist-b1f49";
const DISTRICT_ID   = process.env.DISTRICT_ID      || "all";
const BUCKET_NAME   = process.env.STORAGE_BUCKET   || `${PROJECT_ID}.appspot.com`;

if (!getApps().length) {
  initializeApp({ projectId: PROJECT_ID, storageBucket: BUCKET_NAME });
}

const db      = getFirestore();
const storage = getStorage().bucket();

// ---------------------------------------------------------------------------
// Sample grounding content
// ---------------------------------------------------------------------------

const GROUNDING_CONTENT = [
  {
    gradeLevel: "5",
    subject:    "Math",
    title:      "Place Value and Decimals",
    standard:   "5.NBT.A.1",
    storagePath: "grounding/student-content/5/Math/place-value-decimals.txt",
    content:
      `PLACE VALUE AND DECIMALS — Grade 5 (Standard: 5.NBT.A.1)

In the decimal system each place is 10 times the value of the place to its right.

PLACE VALUE CHART
Hundreds | Tens | Ones . Tenths | Hundredths | Thousandths
  100   |  10  |  1  .  0.1   |   0.01    |   0.001

KEY CONCEPTS
• The digit 3 in 3.14 is worth 3 ones (3.0).
• The digit 1 in 3.14 is worth 1 tenth (0.1).
• The digit 4 in 3.14 is worth 4 hundredths (0.04).

COMPARING DECIMALS
Line up the decimal points, then compare digit by digit from left to right.
Example: 2.47 > 2.39 because 4 tenths > 3 tenths.

ROUNDING
To round to the nearest tenth, look at the hundredths digit.
• 5 or greater → round up. Less than 5 → round down.
Example: 3.46 rounded to the nearest tenth = 3.5.`,
  },
  {
    gradeLevel: "5",
    subject:    "Science",
    title:      "Photosynthesis",
    standard:   "5-LS1-1",
    storagePath: "grounding/student-content/5/Science/photosynthesis.txt",
    content:
      `PHOTOSYNTHESIS — Grade 5 (Standard: 5-LS1-1)

Photosynthesis is the process plants use to make their own food using sunlight.

THE EQUATION
Carbon dioxide + Water + Sunlight → Glucose + Oxygen
CO₂ + H₂O + light energy → C₆H₁₂O₆ + O₂

WHERE IT HAPPENS
Photosynthesis takes place inside chloroplasts — organelles found in plant cells.
Chlorophyll (the green pigment) absorbs red and blue light to power the reaction.

INPUTS (what the plant needs)
• Carbon dioxide — absorbed through tiny pores called stomata
• Water — absorbed by roots, travels up the stem
• Sunlight — captured by chlorophyll

OUTPUTS (what the plant makes)
• Glucose — used by the plant for energy and growth
• Oxygen — released into the air (we breathe it!)

WHY IT MATTERS
Photosynthesis is the foundation of most food chains on Earth.
Plants are producers — they capture the sun's energy and store it in food.`,
  },
  {
    gradeLevel: "8",
    subject:    "Math",
    title:      "Linear Equations",
    standard:   "8.EE.C.7",
    storagePath: "grounding/student-content/8/Math/linear-equations.txt",
    content:
      `LINEAR EQUATIONS — Grade 8 (Standard: 8.EE.C.7)

A linear equation has the form ax + b = c, where x is the variable.

SOLVING STEPS
1. Simplify each side (combine like terms, distribute if needed).
2. Get variable terms on one side using inverse operations.
3. Isolate the variable by dividing or multiplying.
4. Check your answer by substituting back into the original equation.

EXAMPLE: Solve 2x + 5 = 13
  2x + 5 = 13
  2x     = 8    (subtract 5 from both sides)
  x      = 4    (divide both sides by 2)
Check: 2(4) + 5 = 8 + 5 = 13 ✓

SPECIAL CASES
• No solution: 2x + 3 = 2x + 7 → 3 = 7 (contradiction — never true)
• Infinite solutions: 2x + 4 = 2(x + 2) → 4 = 4 (identity — always true)`,
  },
];

const CURRICULUM_CONTENT = [
  {
    gradeLevel: "5",
    subject:    "Math",
    title:      "Grade 5 Math Scope and Sequence",
    standard:   "5.NBT",
    storagePath: "grounding/curriculum/5/Math/scope-sequence.txt",
    content:
      `GRADE 5 MATH — SCOPE AND SEQUENCE

UNIT 1: Place Value and Operations (Weeks 1–6)
  • Understand place value to billions and thousandths (5.NBT.A.1)
  • Read, write, and compare decimals to thousandths (5.NBT.A.3)
  • Multiply and divide multi-digit whole numbers (5.NBT.B.5, 5.NBT.B.6)

UNIT 2: Fractions (Weeks 7–14)
  • Add and subtract fractions with unlike denominators (5.NF.A.1)
  • Multiply fractions and mixed numbers (5.NF.B.4)
  • Divide fractions by whole numbers and whole numbers by fractions (5.NF.B.7)

UNIT 3: Measurement and Data (Weeks 15–20)
  • Convert measurement units within the same system (5.MD.A.1)
  • Represent and interpret data in line plots (5.MD.B.2)
  • Find volumes of rectangular prisms (5.MD.C.3)

UNIT 4: Geometry (Weeks 21–26)
  • Graph points on the coordinate plane (5.G.A.1)
  • Classify two-dimensional figures (5.G.B.3)`,
  },
];

const POLICIES = [
  {
    districtId: DISTRICT_ID,
    title:      "Student Acceptable Use Policy",
    content:
      `STUDENT ACCEPTABLE USE POLICY
EduAssist AI Companion

PERMITTED USES
• Asking questions about assigned curriculum content
• Getting step-by-step explanations of academic concepts
• Reviewing practice problems with guided feedback
• Exploring career paths and academic options

PROHIBITED USES
• Completing homework or assessments on the student's behalf
• Discussing violence, weapons, drugs, or sexual content
• Sharing personal information (full name, address, phone)

PRIVACY
All conversations are logged and may be reviewed by teachers and administrators.`,
  },
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function uploadAndSeed(items, firestoreCollection) {
  for (const item of items) {
    process.stdout.write(`  Uploading ${item.storagePath} ... `);
    await storage.file(item.storagePath).save(Buffer.from(item.content, "utf-8"), {
      contentType: "text/plain",
      metadata: { cacheControl: "public, max-age=3600" },
    });
    const { content: _, storagePath, ...meta } = item;
    await db.collection(firestoreCollection).add({
      ...meta,
      storagePath,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log("done");
  }
}

async function seedPolicies() {
  for (const policy of POLICIES) {
    process.stdout.write(`  Seeding policy: ${policy.title} ... `);
    await db.collection("districtPolicies").add({
      ...policy,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log("done");
  }
}

async function main() {
  console.log(`\nSeeding Firebase content for project: ${PROJECT_ID}`);
  console.log(`Storage bucket: ${BUCKET_NAME}`);
  console.log(`District ID: ${DISTRICT_ID}\n`);

  console.log("Step 1: Student grounding content (groundingContent collection)");
  await uploadAndSeed(GROUNDING_CONTENT, "groundingContent");

  console.log("\nStep 2: Curriculum content (curriculumContent collection)");
  await uploadAndSeed(CURRICULUM_CONTENT, "curriculumContent");

  console.log("\nStep 3: District policies (districtPolicies collection)");
  await seedPolicies();

  console.log("\n=== Seeding complete ===");
  console.log("Next: set documentBackend in districtConfig or use the IT Admin Setup view in the app.");
  process.exit(0);
}

main().catch((err) => {
  console.error("\nFailed:", err.message);
  process.exit(1);
});
