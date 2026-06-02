"use strict";

/**
 * Word limit and truncation tests (FR-008).
 * Verifies grade-band limits, word counting, and sentence-boundary truncation.
 */

const { getWordLimit, getGradeBand, countWords, truncateToWordLimit } =
  require("../index")._test;

// ---------------------------------------------------------------------------
// Grade band assignment
// ---------------------------------------------------------------------------
describe("getGradeBand", () => {
  const cases = [
    ["K",  "K-2"],
    ["1",  "K-2"],
    ["2",  "K-2"],
    ["3",  "3-5"],
    ["4",  "3-5"],
    ["5",  "3-5"],
    ["6",  "6-8"],
    ["7",  "6-8"],
    ["8",  "6-8"],
    ["9",  "9-12"],
    ["10", "9-12"],
    ["11", "9-12"],
    ["12", "9-12"],
    ["",   "9-12"],   // unknown → most permissive band
    [null, "9-12"],
  ];

  test.each(cases)("grade %s → band %s", (grade, expectedBand) => {
    expect(getGradeBand(grade)).toBe(expectedBand);
  });
});

// ---------------------------------------------------------------------------
// Word limits per grade band
// ---------------------------------------------------------------------------
describe("getWordLimit", () => {
  test("K-2 limit is 60 words", () => {
    expect(getWordLimit("1").wordLimit).toBe(60);
  });

  test("3-5 limit is 80 words", () => {
    expect(getWordLimit("4").wordLimit).toBe(80);
  });

  test("6-8 limit is 150 words", () => {
    expect(getWordLimit("7").wordLimit).toBe(150);
  });

  test("9-12 limit is 250 words", () => {
    expect(getWordLimit("11").wordLimit).toBe(250);
  });

  test("maxTokens is always greater than wordLimit", () => {
    ["1", "4", "7", "11"].forEach((grade) => {
      const { wordLimit, maxTokens } = getWordLimit(grade);
      expect(maxTokens).toBeGreaterThan(wordLimit);
    });
  });
});

// ---------------------------------------------------------------------------
// Word counter
// ---------------------------------------------------------------------------
describe("countWords", () => {
  test("counts simple sentence", () => {
    expect(countWords("one two three")).toBe(3);
  });

  test("handles extra whitespace", () => {
    expect(countWords("  one   two  three  ")).toBe(3);
  });

  test("handles empty string", () => {
    expect(countWords("")).toBe(0);
  });

  test("handles single word", () => {
    expect(countWords("hello")).toBe(1);
  });

  test("handles newlines as whitespace", () => {
    expect(countWords("one\ntwo\nthree")).toBe(3);
  });
});

// ---------------------------------------------------------------------------
// Truncation — within limit: no change
// ---------------------------------------------------------------------------
describe("truncateToWordLimit — within limit", () => {
  test("text at exactly the limit is returned unchanged", () => {
    const words = Array(80).fill("word").join(" ");
    expect(truncateToWordLimit(words, 80)).toBe(words);
  });

  test("text under the limit is returned unchanged", () => {
    const text = "This is a short sentence.";
    expect(truncateToWordLimit(text, 80)).toBe(text);
  });
});

// ---------------------------------------------------------------------------
// Truncation — over limit: cut at sentence boundary
// ---------------------------------------------------------------------------
describe("truncateToWordLimit — over limit", () => {
  test("appends ellipsis when truncated", () => {
    const longText = Array(100).fill("word").join(" ") + ".";
    const result = truncateToWordLimit(longText, 60);
    expect(result).toContain("…");
    expect(countWords(result.replace(" …", ""))).toBeLessThanOrEqual(60);
  });

  test("cuts at sentence boundary when possible", () => {
    // 20 words then a period, then 80 more words
    const firstSentence = Array(20).fill("hello").join(" ") + ".";
    const rest = " " + Array(80).fill("extra").join(" ");
    const result = truncateToWordLimit(firstSentence + rest, 30);
    // Should end with the sentence punctuation + ellipsis, not mid-word
    expect(result).toMatch(/\.\s*…$/);
  });

  test("falls back to hard word-limit cut when no sentence boundary", () => {
    // A single run of words with no punctuation
    const text = Array(200).fill("word").join(" ");
    const result = truncateToWordLimit(text, 50);
    expect(result).toContain("…");
    // Word count of result (without the ellipsis marker) must be ≤ 50
    const wordCount = countWords(result.replace(/\s*…$/, ""));
    expect(wordCount).toBeLessThanOrEqual(50);
  });

  test("never truncates mid-sentence for K-2 limit (60 words)", () => {
    // Simulate a response that is slightly over the K-2 60-word limit
    const sentence1 = Array(40).fill("word").join(" ") + ".";
    const sentence2 = " " + Array(40).fill("more").join(" ") + ".";
    const result = truncateToWordLimit(sentence1 + sentence2, 60);
    // Must end cleanly
    expect(result).toMatch(/[.!?]\s*…$|[.!?]$/);
  });
});
