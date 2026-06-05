#!/usr/bin/env node
/**
 * Reads parsed NC DPI Standard Course of Study records from the local JSONL mirror
 * and seeds them into the Firestore `ncStandards` collection.
 *
 * Only records with recordType === "standard" and parseStatus === "parsed" are written.
 * Records with approvalStatus "NeedsReview" are preserved as-is — admin approval
 * via the app UI promotes them to "Approved" before they become searchable by teachers.
 *
 * Prerequisites:
 *   gcloud auth application-default login
 *   cd EduAssistall/functions && npm install
 *
 * Usage (from EduAssistall/ root):
 *   FIREBASE_PROJECT=eduassist-b1f49 node scripts/seed-nc-standards.js
 *
 * Optional env vars:
 *   FIREBASE_PROJECT  — Firebase project ID (default: eduassist-b1f49)
 *   DRY_RUN=1         — Print counts without writing to Firestore
 *   SUBJECT=Mathematics — Seed only one subject (useful for testing)
 */

const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getFirestore }                  = require("firebase-admin/firestore");
const fs                                = require("fs");
const path                              = require("path");
const readline                          = require("readline");

const PROJECT_ID = process.env.FIREBASE_PROJECT || "eduassist-b1f49";
const DRY_RUN    = process.env.DRY_RUN === "1";
const SUBJECT_FILTER = process.env.SUBJECT || null;

if (!getApps().length) {
  initializeApp({ projectId: PROJECT_ID });
}
const db = getFirestore();

const JSONL_PATH = path.resolve(
  __dirname,
  "../docs/nc-standard-course-of-study/parsed/standards-records.jsonl"
);
const BATCH_SIZE = 490; // Firestore limit is 500 writes per batch

async function main() {
  if (!fs.existsSync(JSONL_PATH)) {
    console.error(`JSONL not found at: ${JSONL_PATH}`);
    process.exit(1);
  }

  console.log(`Reading standards from: ${JSONL_PATH}`);
  if (DRY_RUN) console.log("DRY RUN — no data will be written.");
  if (SUBJECT_FILTER) console.log(`Filtering to subject: ${SUBJECT_FILTER}`);

  const records = [];
  const rl = readline.createInterface({ input: fs.createReadStream(JSONL_PATH) });

  await new Promise((resolve) => {
    rl.on("line", (line) => {
      if (!line.trim()) return;
      try {
        const record = JSON.parse(line);
        if (record.recordType !== "standard") return;
        if (record.parseStatus !== "parsed") return;
        if (SUBJECT_FILTER && record.subject !== SUBJECT_FILTER) return;
        records.push(record);
      } catch {
        // skip malformed lines
      }
    });
    rl.on("close", resolve);
  });

  console.log(`Found ${records.length} parseable standard records.`);

  const bySubject = {};
  records.forEach((r) => {
    bySubject[r.subject] = (bySubject[r.subject] || 0) + 1;
  });
  console.log("By subject:", bySubject);

  if (DRY_RUN) {
    console.log("Dry run complete. Pass no DRY_RUN env var to write.");
    return;
  }

  let written = 0;
  let batchNum = 0;

  for (let i = 0; i < records.length; i += BATCH_SIZE) {
    const chunk = records.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    chunk.forEach((record) => {
      const ref = db.collection("ncStandards").doc(record.id);
      batch.set(ref, {
        id:             record.id,
        standardCode:   record.standardCode || "",
        standardText:   record.standardText || "",
        subject:        record.subject || "",
        gradeLevel:     record.gradeLevel || "",
        course:         record.course || "",
        effectiveYear:  record.effectiveYear || 2024,
        approvalStatus: record.approvalStatus || "NeedsReview",
        sourceFile:     record.sourceFile || "",
        parseStatus:    record.parseStatus,
        seededAt:       new Date().toISOString(),
      });
    });

    await batch.commit();
    written += chunk.length;
    batchNum++;
    console.log(`Batch ${batchNum}: wrote ${chunk.length} records (${written}/${records.length} total)`);
  }

  console.log(`Done. ${written} NC standards seeded to Firestore ncStandards collection.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
