/**
 * seed.js — wipes Firebase Auth users + key Firestore collections and inserts
 * a clean set of test accounts for end-to-end flow testing.
 *
 * Usage (from EduAssistall/functions/):
 *   node seed.js
 *
 * Requires Application Default Credentials:
 *   gcloud auth application-default login   (one-time setup)
 *
 * Test accounts created:
 *   teacher@eduassist.test  /  EduTest2024!
 *   alex@eduassist.test     /  EduTest2024!
 *   parent@eduassist.test   /  EduTest2024!
 */

const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "eduassist-b1f49",
});

const auth = admin.auth();
const db   = admin.firestore();

// ─── helpers ────────────────────────────────────────────────────────────────

async function deleteAllAuthUsers() {
  let pageToken;
  let total = 0;
  do {
    const result = await auth.listUsers(1000, pageToken);
    if (result.users.length === 0) break;
    await auth.deleteUsers(result.users.map(u => u.uid));
    total += result.users.length;
    pageToken = result.pageToken;
  } while (pageToken);
  console.log(`  deleted ${total} auth user(s)`);
}

async function deleteCollection(collectionPath) {
  const snap = await db.collection(collectionPath).get();
  if (snap.empty) return;
  const batches = [];
  let batch = db.batch();
  let count = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    if (++count % 500 === 0) { batches.push(batch.commit()); batch = db.batch(); }
  }
  batches.push(batch.commit());
  await Promise.all(batches);
  console.log(`  cleared ${snap.size} doc(s) from ${collectionPath}`);
}

// ─── main ────────────────────────────────────────────────────────────────────

async function seed() {
  console.log("\n=== 1. Clearing Firebase Auth users ===");
  await deleteAllAuthUsers();

  console.log("\n=== 2. Clearing Firestore collections ===");
  const collections = [
    "users", "studentAdultLinks", "learningProfiles",
    "classroomConfig", "parentInvitations", "conversations",
    "learningPaths", "studentProgress",
  ];
  for (const c of collections) await deleteCollection(c);

  console.log("\n=== 3. Creating test users ===");

  // ── Teacher ─────────────────────────────────────────────────────────────
  const teacher = await auth.createUser({
    email: "teacher@eduassist.test",
    password: "EduTest2024!",
    displayName: "Ms. Johnson",
    emailVerified: true,
  });
  await db.collection("users").doc(teacher.uid).set({
    id: teacher.uid,
    email: "teacher@eduassist.test",
    displayName: "Ms. Johnson",
    role: "teacher",
    onboardingComplete: true,
    privacyConsentGiven: true,
    privacyConsentAt: admin.firestore.FieldValue.serverTimestamp(),
    timezone: "America/New_York",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection("classroomConfig").doc(teacher.uid).set({
    id: teacher.uid,
    teacherId: teacher.uid,
    school: "Lincoln Elementary",
    gradeRanges: ["6–8"],
    defaultInteractionMode: "guidedDiscovery",
    allowedInteractionModes: ["guidedDiscovery", "directAnswer", "socraticMethod"],
    answerModeEnabledByDefault: false,
    responseStyle: "standard",
  });
  console.log(`  teacher  uid=${teacher.uid}  email=teacher@eduassist.test`);

  // ── Student ──────────────────────────────────────────────────────────────
  const student = await auth.createUser({
    email: "alex@eduassist.test",
    password: "EduTest2024!",
    displayName: "Alex Smith",
    emailVerified: true,
  });
  await db.collection("users").doc(student.uid).set({
    id: student.uid,
    email: "alex@eduassist.test",
    displayName: "Alex Smith",
    role: "student",
    onboardingComplete: true,
    privacyConsentGiven: true,
    privacyConsentAt: admin.firestore.FieldValue.serverTimestamp(),
    timezone: "America/New_York",
    parentalConsentStatus: "not_required",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection("learningProfiles").doc(student.uid).set({
    studentId: student.uid,
    grade: "7",
    varkStyle: "visual",
    interests: ["science", "technology"],
    assessmentCompleted: true,
    defaultInteractionMode: "guidedDiscovery",
    allowedInteractionModes: ["guidedDiscovery", "directAnswer", "socraticMethod"],
    currentInteractionMode: "guidedDiscovery",
    responseStyle: "standard",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`  student  uid=${student.uid}  email=alex@eduassist.test`);

  // ── Parent ───────────────────────────────────────────────────────────────
  const parent = await auth.createUser({
    email: "parent@eduassist.test",
    password: "EduTest2024!",
    displayName: "Sarah Smith",
    emailVerified: true,
  });
  await db.collection("users").doc(parent.uid).set({
    id: parent.uid,
    email: "parent@eduassist.test",
    displayName: "Sarah Smith",
    role: "parent",
    onboardingComplete: true,
    privacyConsentGiven: true,
    privacyConsentAt: admin.firestore.FieldValue.serverTimestamp(),
    timezone: "America/New_York",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`  parent   uid=${parent.uid}  email=parent@eduassist.test`);

  console.log("\n=== 4. Creating student ↔ adult links ===");

  // Teacher → Student link
  const teacherLinkId = `${teacher.uid}_${student.uid}`;
  await db.collection("studentAdultLinks").doc(teacherLinkId).set({
    id: teacherLinkId,
    adultId: teacher.uid,
    studentId: student.uid,
    adultRole: "teacher",
    studentEmail: "alex@eduassist.test",
    confirmed: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`  teacher→student  linkId=${teacherLinkId}`);

  // Parent → Student link
  const parentLinkId = `${parent.uid}_${student.uid}`;
  await db.collection("studentAdultLinks").doc(parentLinkId).set({
    id: parentLinkId,
    adultId: parent.uid,
    studentId: student.uid,
    adultRole: "parent",
    studentEmail: "alex@eduassist.test",
    confirmed: true,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`  parent→student   linkId=${parentLinkId}`);

  console.log("\n=== Done ===");
  console.log("\nTest credentials:");
  console.log("  Teacher : teacher@eduassist.test  /  EduTest2024!");
  console.log("  Student : alex@eduassist.test     /  EduTest2024!");
  console.log("  Parent  : parent@eduassist.test   /  EduTest2024!");
  console.log("\nExpected state after signing in:");
  console.log("  Teacher dashboard → My Students should show Alex Smith");
  console.log("  Parent dashboard  → Overview should show Alex Smith");
  console.log("  Student → Home should show personalized learning content\n");
}

seed().catch(err => {
  console.error("Seed failed:", err.message);
  process.exit(1);
});
