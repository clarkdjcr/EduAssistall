#!/usr/bin/env node
/**
 * Seeds the 198 NC ELA daily lesson plan markdown files into Firestore
 * as `dailyLessonPlans` documents. Each document includes the standard
 * metadata, the generic student assignment shell, and the AI-generated
 * suggested content (text, activities, student prompt).
 *
 * Run once; safe to re-run — existing documents are skipped by dayNumber.
 *
 * Prerequisites:
 *   gcloud auth application-default login
 *   cd EduAssistall/functions && npm install
 *
 * Usage (from project root):
 *   FIREBASE_PROJECT=eduassist-b1f49 node scripts/seed-lesson-plans.js
 *
 * Optional env vars:
 *   LESSON_PLANS_DIR  — path to the output/ folder of day-*.md files
 *   FIREBASE_PROJECT  — Firebase project ID
 */

const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getFirestore, FieldValue }      = require("firebase-admin/firestore");
const fs   = require("fs");
const path = require("path");
const os   = require("os");

const PROJECT_ID = process.env.FIREBASE_PROJECT || "eduassist-b1f49";
const PLANS_DIR  = process.env.LESSON_PLANS_DIR ||
  path.join(os.homedir(),
    "Library/Mobile Documents/com~apple~CloudDocs/AIos complete/AIos/Workflow/education-daily-lesson-plans/output");

if (!getApps().length) {
  initializeApp({ projectId: PROJECT_ID });
}
const db = getFirestore();

// ── Helpers ──────────────────────────────────────────────────────────────────

function normalizeGradeLevel(grade) {
  if (/kindergarten/i.test(grade)) return "K";
  const bandMatch = grade.match(/Grades?\s+(\d+-\d+)/i);
  if (bandMatch) return bandMatch[1];
  const numMatch = grade.match(/Grade\s+(\d+)/i);
  if (numMatch) return numMatch[1];
  return grade;
}

function extractSection(text, header) {
  const re = new RegExp(`## ${header}[\\s\\S]*?(?=## |$)`, "i");
  const m = text.match(re);
  return m ? m[0] : "";
}

function extractBulletItems(text) {
  return text
    .split("\n")
    .filter(l => /^[-*]\s/.test(l.trim()))
    .map(l => l.replace(/^[-*]\s+/, "").trim())
    .filter(Boolean);
}

function stripMarkdownFormatting(text) {
  return text
    .replace(/\*\*(.+?)\*\*/g, "$1")
    .replace(/\*(.+?)\*/g, "$1")
    .replace(/`(.+?)`/g, "$1")
    .trim();
}

function parsePlan(filepath) {
  const content = fs.readFileSync(filepath, "utf8");
  const filename = path.basename(filepath);

  // ── Day number from filename ──
  const dayMatch = filename.match(/day-(\d+)/);
  const dayNumber = dayMatch ? parseInt(dayMatch[1], 10) : 0;

  // ── Grade ──
  const gradeMatch = content.match(/^\*\*Grade:\*\*\s*(.+)$/m);
  const grade = gradeMatch ? gradeMatch[1].trim() : "Unknown";
  const gradeLevel = normalizeGradeLevel(grade);

  // ── Standard code + description (first bold — em-dash line in Learning Focus) ──
  const stdMatch = content.match(/\*\*([A-Z0-9][A-Z0-9\-\.]+)\*\*\s+[—–]\s+(.+)/);
  const standardCode        = stdMatch ? stdMatch[1].trim() : "";
  const standardDescription = stdMatch ? stdMatch[2].trim() : "";

  // ── Strand ──
  const strandMatch = content.match(/Strand:\s*(.+)/);
  const strand = strandMatch ? strandMatch[1].trim() : "";

  // ── Sub-standards from "Use the text to practice:" ──
  const subMatch = content.match(/Use the text to practice:\s*(.+?)(?:\n|$)/);
  const subStandards = subMatch
    ? subMatch[1].split(";").map(s => s.trim()).filter(Boolean)
    : [];

  // ── Student assignment (full section text, minus the header) ──
  const assignSection = extractSection(content, "Student Assignment");
  const studentAssignment = assignSection
    .replace(/^## Student Assignment\n/, "")
    .trim();

  // ── Evidence of Learning items ──
  const evidenceSection = extractSection(content, "Evidence Of Learning");
  const evidenceOfLearning = extractBulletItems(evidenceSection);

  // ── Suggested Content section ──
  const suggestedSection = extractSection(content, "Suggested Content");

  // Primary text
  const primaryMatch = suggestedSection.match(/\*\*Primary:\*\*\s*(.+)/);
  const suggestedPrimaryText = primaryMatch
    ? stripMarkdownFormatting(primaryMatch[1].trim())
    : "";

  // Alternative text
  const altMatch = suggestedSection.match(/\*\*Alternative:\*\*\s*(.+)/);
  const suggestedAlternativeText = altMatch
    ? stripMarkdownFormatting(altMatch[1].trim())
    : "";

  // Activities (numbered list items)
  const suggestedActivities = suggestedSection
    .split("\n")
    .filter(l => /^\d+\./.test(l.trim()))
    .map(l => l.replace(/^\d+\.\s*/, "").trim())
    .filter(Boolean);

  // Student prompt (blockquote in the "Suggested Student Prompt" sub-section)
  const promptSectionMatch = suggestedSection.match(
    /### Suggested Student Prompt\n([\s\S]*?)(?=###|$)/
  );
  let suggestedStudentPrompt = "";
  if (promptSectionMatch) {
    const promptLines = promptSectionMatch[1]
      .split("\n")
      .filter(l => l.trim().startsWith(">"))
      .map(l => l.replace(/^>\s*/, "").trim())
      .filter(Boolean);
    suggestedStudentPrompt = promptLines.join(" ");
  }

  return {
    dayNumber,
    grade,
    gradeLevel,
    standardCode,
    standardDescription,
    strand,
    subStandards,
    studentAssignment,
    evidenceOfLearning,
    suggestedPrimaryText,
    suggestedAlternativeText,
    suggestedActivities,
    suggestedStudentPrompt,
    // Edited fields start null — the teacher fills these in the app
    editedPrimaryText:     null,
    editedAlternativeText: null,
    editedActivities:      null,
    editedStudentPrompt:   null,
    teacherNotes:          "",
    subject:               "ELA",
    sourceFile:            filename,
    status:                "draft",
    createdAt:             FieldValue.serverTimestamp(),
  };
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  if (!fs.existsSync(PLANS_DIR)) {
    console.error(`\nLesson plans directory not found:\n  ${PLANS_DIR}`);
    console.error("Set LESSON_PLANS_DIR env var to the correct path.");
    process.exit(1);
  }

  const files = fs
    .readdirSync(PLANS_DIR)
    .filter(f => f.match(/^day-\d+\.md$/))
    .sort();

  console.log(`\nProject:  ${PROJECT_ID}`);
  console.log(`Source:   ${PLANS_DIR}`);
  console.log(`Files:    ${files.length}\n`);

  // Fetch existing day numbers so we can skip already-seeded documents
  const existing = new Set();
  const snap = await db.collection("dailyLessonPlans").select("dayNumber").get();
  snap.forEach(doc => existing.add(doc.data().dayNumber));
  if (existing.size > 0) {
    console.log(`Already seeded: ${existing.size} documents (will skip)\n`);
  }

  let seeded = 0;
  let skipped = 0;
  let errors = 0;

  for (const filename of files) {
    const filepath = path.join(PLANS_DIR, filename);
    try {
      const plan = parsePlan(filepath);
      if (existing.has(plan.dayNumber)) {
        process.stdout.write(`  – day-${String(plan.dayNumber).padStart(3, "0")} already exists (skip)\n`);
        skipped++;
        continue;
      }
      await db.collection("dailyLessonPlans").add(plan);
      process.stdout.write(`  ✓ day-${String(plan.dayNumber).padStart(3, "0")} ${plan.standardCode} (${plan.grade})\n`);
      seeded++;
    } catch (err) {
      console.error(`  ✗ ${filename}: ${err.message}`);
      errors++;
    }
  }

  console.log(`\n${"─".repeat(50)}`);
  console.log(`Done: ${seeded} seeded, ${skipped} skipped, ${errors} errors`);
  console.log(`\nFirestore collection: dailyLessonPlans`);
  console.log(`Next steps:`);
  console.log(`  1. Deploy updated firestore.rules`);
  console.log(`  2. Build the app and open Create → Daily Lesson Plans`);
  process.exit(errors > 0 ? 1 : 0);
}

main().catch(err => {
  console.error("\nFailed:", err.message);
  process.exit(1);
});
