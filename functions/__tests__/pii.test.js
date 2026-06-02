"use strict";

/**
 * PII detection and redaction tests (FR-104).
 * Verifies that personal information is stripped before messages reach Claude or Firestore.
 */

const { detectAndRedactPII } = require("../index")._test;

// ---------------------------------------------------------------------------
// Should detect and redact PII
// ---------------------------------------------------------------------------
describe("detectAndRedactPII — detects and redacts", () => {
  test("US phone number — dashes", () => {
    const { hasPII, redactedText } = detectAndRedactPII("call me at 555-867-5309");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:phone_number]");
    expect(redactedText).not.toContain("555-867-5309");
  });

  test("US phone number — parentheses format", () => {
    const { hasPII, redactedText } = detectAndRedactPII("my number is (555) 867-5309");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:phone_number]");
  });

  test("email address", () => {
    const { hasPII, redactedText } = detectAndRedactPII("email me at student@school.edu");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:email_address]");
    expect(redactedText).not.toContain("student@school.edu");
  });

  test("Social Security Number — dashes", () => {
    const { hasPII, redactedText } = detectAndRedactPII("my SSN is 123-45-6789");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:ssn]");
  });

  test("street address", () => {
    const { hasPII, redactedText } = detectAndRedactPII("I live at 123 Main Street");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:street_address]");
  });

  test("URL", () => {
    const { hasPII, redactedText } = detectAndRedactPII("check out https://myprofile.com/johnsmith");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:url]");
  });

  test("name disclosure — 'my name is'", () => {
    const { hasPII, redactedText } = detectAndRedactPII("my name is John Smith");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:name_disclosure]");
    expect(redactedText).not.toContain("John Smith");
  });

  test("name disclosure — 'I am'", () => {
    const { hasPII, redactedText } = detectAndRedactPII("I am Sarah Johnson and I need help");
    expect(hasPII).toBe(true);
    expect(redactedText).toContain("[REDACTED:name_disclosure]");
  });

  test("multiple PII types in one message", () => {
    const msg = "call me at 555-123-4567 or email john@test.com";
    const { hasPII, redactedText, detectedTypes } = detectAndRedactPII(msg);
    expect(hasPII).toBe(true);
    expect(detectedTypes).toContain("phone_number");
    expect(detectedTypes).toContain("email_address");
    expect(redactedText).not.toContain("555-123-4567");
    expect(redactedText).not.toContain("john@test.com");
  });
});

// ---------------------------------------------------------------------------
// Should NOT redact clean educational messages (no false positives)
// ---------------------------------------------------------------------------
describe("detectAndRedactPII — no false positives on clean messages", () => {
  const cases = [
    "what is photosynthesis",
    "help me understand fractions",
    "who was George Washington",
    "explain the water cycle",
    "what is 7 times 8",
    "I need help with my essay about World War II",
    "my teacher assigned chapter 5",
  ];

  test.each(cases)('does not alter "%s"', (text) => {
    const { hasPII, redactedText } = detectAndRedactPII(text);
    expect(hasPII).toBe(false);
    expect(redactedText).toBe(text);
  });
});

// ---------------------------------------------------------------------------
// Redaction preserves non-PII surrounding text
// ---------------------------------------------------------------------------
test("surrounding text is preserved after redaction", () => {
  const { redactedText } = detectAndRedactPII(
    "Please help me with math. My number is 555-123-4567. Thanks!"
  );
  expect(redactedText).toContain("Please help me with math.");
  expect(redactedText).toContain("[REDACTED:phone_number]");
  expect(redactedText).toContain("Thanks!");
});

// ---------------------------------------------------------------------------
// detectedTypes array is populated correctly
// ---------------------------------------------------------------------------
test("detectedTypes reflects all found PII categories", () => {
  const { detectedTypes } = detectAndRedactPII(
    "email me at a@b.com or call 555-867-5309"
  );
  expect(detectedTypes).toContain("email_address");
  expect(detectedTypes).toContain("phone_number");
  expect(detectedTypes.length).toBeGreaterThanOrEqual(2);
});

test("detectedTypes is empty for clean messages", () => {
  const { detectedTypes } = detectAndRedactPII("explain how rainbows form");
  expect(detectedTypes).toHaveLength(0);
});
