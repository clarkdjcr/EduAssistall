#!/usr/bin/env node

/*
 * Parses the local NC DPI Standard Course of Study Markdown mirror into
 * structured JSONL records. This is intentionally conservative: clear
 * standards become `standard` records, and files without reliable standard
 * boundaries become `document` records for human review/seeding.
 */

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const SOURCE_DIR = path.join(ROOT, "docs", "nc-standard-course-of-study");
const OUT_DIR = path.join(SOURCE_DIR, "parsed");
const MANIFEST_PATH = path.join(SOURCE_DIR, "crawl_manifest.json");

const STANDARD_CODE_RE = /(?:NC\.)?[A-Z0-9]{1,4}(?:[.&/-][A-Z0-9]{1,8}){1,8}/;
const STANDARD_LINE_RE = new RegExp(`^(?:[-*]\\s+)?(${STANDARD_CODE_RE.source})\\s+(.{8,})$`);
const NON_STANDARD_PREFIX_RE = /^(?:http|source_url|title|kind|status|retrieved|subject|grade|duration|standard):/i;

const GRADE_PATTERNS = [
  [/kindergarten|\bgrade k\b|\bk\b/i, "K"],
  [/\b(?:first|1st|grade 1)\b/i, "1"],
  [/\b(?:second|2nd|grade 2)\b/i, "2"],
  [/\b(?:third|3rd|grade 3)\b/i, "3"],
  [/\b(?:fourth|4th|grade 4)\b/i, "4"],
  [/\b(?:fifth|5th|grade 5)\b/i, "5"],
  [/\b(?:sixth|6th|grade 6)\b/i, "6"],
  [/\b(?:seventh|7th|grade 7)\b/i, "7"],
  [/\b(?:eighth|8th|grade 8)\b/i, "8"],
  [/\bgrades? 9-10\b/i, "9-10"],
  [/\bgrades? 11-12\b/i, "11-12"],
  [/\bgrades? 9-12\b/i, "9-12"],
  [/\bmiddle school\b/i, "6-8"],
  [/\bhigh school\b/i, "9-12"],
];

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function sha256(text) {
  return crypto.createHash("sha256").update(text).digest("hex");
}

function parseFrontMatter(text) {
  if (!text.startsWith("---\n")) return [{}, text];
  const end = text.indexOf("\n---", 4);
  if (end < 0) return [{}, text];
  const raw = text.slice(4, end).trim();
  const body = text.slice(end + 4).trim();
  const meta = {};
  for (const line of raw.split(/\n/)) {
    const match = line.match(/^([A-Za-z_]+):\s*"?([^"]*)"?\s*$/);
    if (match) meta[match[1]] = match[2];
  }
  return [meta, body];
}

function normalizeWhitespace(value) {
  return value.replace(/[ \t]+/g, " ").replace(/\n{3,}/g, "\n\n").trim();
}

function inferGrade(title, filename) {
  const source = `${title} ${filename}`;
  if (/\bk-12\b/i.test(source) && !/\bkindergarten\b|\bgrade k\b|\bk\b/i.test(filename)) return "";
  for (const [re, grade] of GRADE_PATTERNS) {
    if (re.test(source)) return grade;
  }
  return "";
}

function inferGradeFromCode(code) {
  if (/^(?:NC\.)?K[.&/-]/.test(code)) return "K";
  const gradeMatch = code.match(/^(?:NC\.)?(\d{1,2})(?:[.&/-]|$)/);
  if (gradeMatch) return gradeMatch[1];
  const elaMatch = code.match(/^[A-Z]{1,4}\.(K|\d{1,2}(?:-\d{1,2})?)\./);
  if (elaMatch) return elaMatch[1];
  const embeddedMatch = code.match(/[.&/-](K|\d{1,2}(?:-\d{1,2})?)[.&/-]/);
  if (embeddedMatch) return embeddedMatch[1];
  return "";
}

function inferCourse(title, grade) {
  const clean = title.replace(/^.*? - /, "").trim();
  if (grade) return clean;
  return clean || "General";
}

function inferEffectiveYear(title, body) {
  const source = `${title}\n${body.slice(0, 2500)}`;
  const years = [...source.matchAll(/\b(20[0-4][0-9])\b/g)].map((m) => Number(m[1]));
  if (years.length === 0) return null;
  return Math.max(...years);
}

function isLikelyStandardCode(code) {
  if (!code.includes(".") || code.includes("..")) return false;
  if (/^\d/.test(code)) return false;
  if (/www|http|com$/i.test(code)) return false;
  return true;
}

function extractStandards(body) {
  const lines = body.split(/\n/).map((line) => line.trim()).filter(Boolean);
  const chunks = [];
  let current = null;

  for (const line of lines) {
    if (NON_STANDARD_PREFIX_RE.test(line)) continue;
    const match = line.match(STANDARD_LINE_RE);
    if (match && isLikelyStandardCode(match[1])) {
      if (current) chunks.push(current);
      current = {
        code: match[1].replace(/\.$/, ""),
        text: match[2],
        support: [],
      };
      continue;
    }
    if (current) {
      if (/^(clarification|glossary|in the classroom|standard:|cluster:|strand:)/i.test(line)) {
        current.support.push(line);
      } else if (current.support.length < 18 && line.length < 500) {
        current.support.push(line);
      }
    }
  }
  if (current) chunks.push(current);
  return chunks.filter((chunk) => chunk.text.length >= 8);
}

function buildDocumentRecord({ meta, manifestEntry, filename, body }) {
  const title = meta.title || manifestEntry?.title || filename;
  const subject = meta.subject || manifestEntry?.subject || "General";
  const grade = inferGrade(title, filename);
  const course = inferCourse(title, grade);
  return {
    id: sha256(`${filename}:document`).slice(0, 24),
    recordType: "document",
    parseStatus: "needs_review",
    subject,
    gradeLevel: grade,
    course,
    standardCode: "",
    title,
    standardText: normalizeWhitespace(body).slice(0, 4000),
    supportText: "",
    sourceFile: `docs/nc-standard-course-of-study/${filename}`,
    sourceUrl: meta.source_url || manifestEntry?.source_url || "",
    sourceKind: meta.kind || manifestEntry?.kind || "",
    sourceStatus: meta.status || manifestEntry?.status || "",
    effectiveYear: inferEffectiveYear(title, body),
    contentHash: sha256(body),
    approvalStatus: "NeedsReview",
    generatedAt: new Date().toISOString(),
  };
}

function buildStandardRecord({ meta, manifestEntry, filename, body, chunk, index }) {
  const title = meta.title || manifestEntry?.title || filename;
  const subject = meta.subject || manifestEntry?.subject || "General";
  const grade = inferGrade(title, filename) || inferGradeFromCode(chunk.code);
  const course = inferCourse(title, grade);
  const supportText = normalizeWhitespace(chunk.support.join("\n"));
  const standardText = normalizeWhitespace(chunk.text);
  return {
    id: sha256(`${filename}:${chunk.code}:${index}:${standardText}`).slice(0, 24),
    recordType: "standard",
    parseStatus: "parsed",
    subject,
    gradeLevel: grade,
    course,
    standardCode: chunk.code,
    title,
    standardText,
    supportText: supportText.slice(0, 2500),
    sourceFile: `docs/nc-standard-course-of-study/${filename}`,
    sourceUrl: meta.source_url || manifestEntry?.source_url || "",
    sourceKind: meta.kind || manifestEntry?.kind || "",
    sourceStatus: meta.status || manifestEntry?.status || "",
    effectiveYear: inferEffectiveYear(title, body),
    contentHash: sha256(`${chunk.code}\n${standardText}\n${supportText}`),
    approvalStatus: "NeedsReview",
    generatedAt: new Date().toISOString(),
  };
}

function main() {
  if (!fs.existsSync(MANIFEST_PATH)) {
    throw new Error(`Missing manifest at ${path.relative(ROOT, MANIFEST_PATH)}`);
  }
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const manifest = readJson(MANIFEST_PATH);
  const byOutput = new Map(manifest.map((entry) => [entry.output, entry]));
  const records = [];

  for (const entry of manifest) {
    if (!entry.output || entry.status !== "success" || !entry.output.endsWith(".md")) continue;
    const filePath = path.join(SOURCE_DIR, entry.output);
    if (!fs.existsSync(filePath)) continue;
    const raw = fs.readFileSync(filePath, "utf8");
    const [meta, body] = parseFrontMatter(raw);
    const chunks = extractStandards(body);
    if (chunks.length === 0) {
      records.push(buildDocumentRecord({ meta, manifestEntry: byOutput.get(entry.output), filename: entry.output, body }));
      continue;
    }
    chunks.forEach((chunk, index) => {
      records.push(buildStandardRecord({ meta, manifestEntry: byOutput.get(entry.output), filename: entry.output, body, chunk, index }));
    });
  }

  const jsonl = records.map((record) => JSON.stringify(record)).join("\n") + "\n";
  fs.writeFileSync(path.join(OUT_DIR, "standards-records.jsonl"), jsonl);

  const bySubject = {};
  const byGrade = {};
  const byType = {};
  for (const record of records) {
    bySubject[record.subject] = (bySubject[record.subject] || 0) + 1;
    byGrade[record.gradeLevel || "Unspecified"] = (byGrade[record.gradeLevel || "Unspecified"] || 0) + 1;
    byType[record.recordType] = (byType[record.recordType] || 0) + 1;
  }
  const summary = {
    generatedAt: new Date().toISOString(),
    sourceManifest: "docs/nc-standard-course-of-study/crawl_manifest.json",
    recordCount: records.length,
    standardRecordCount: records.filter((record) => record.recordType === "standard").length,
    documentFallbackCount: records.filter((record) => record.recordType === "document").length,
    bySubject,
    byGrade,
    byType,
  };
  fs.writeFileSync(path.join(OUT_DIR, "standards-summary.json"), JSON.stringify(summary, null, 2) + "\n");

  const index = [
    "# Parsed NC Standards",
    "",
    `Generated: ${summary.generatedAt}`,
    "",
    `Records: ${summary.recordCount}`,
    `Parsed standards: ${summary.standardRecordCount}`,
    `Document-level fallback records: ${summary.documentFallbackCount}`,
    "",
    "These records are generated from the local NC DPI Markdown mirror and should be reviewed before being activated as approved curriculum.",
    "",
    "## By Subject",
    "",
    ...Object.entries(bySubject).sort().map(([subject, count]) => `- ${subject}: ${count}`),
    "",
    "## Files",
    "",
    "- `standards-records.jsonl`",
    "- `standards-summary.json`",
  ].join("\n");
  fs.writeFileSync(path.join(OUT_DIR, "INDEX.md"), index + "\n");

  console.log(JSON.stringify(summary, null, 2));
}

main();
