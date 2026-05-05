#!/usr/bin/env node
/**
 * Uploads sample curriculum documents to the SharePoint StudentContent library.
 * Uses app-only auth (client credentials) — the app service principal was granted
 * site owner access during provisioning so no device code flow is needed here.
 *
 * Usage:
 *   node scripts/upload-sample-content.js
 *
 * Required env vars:
 *   AZURE_TENANT_ID / AZURE_CLIENT_ID / AZURE_CLIENT_SECRET
 *   SHAREPOINT_SITE_ID / SHAREPOINT_STUDENT_CONTENT_LIST_ID
 */

const TENANT_ID     = process.env.AZURE_TENANT_ID;
const CLIENT_ID     = process.env.AZURE_CLIENT_ID;
const CLIENT_SECRET = process.env.AZURE_CLIENT_SECRET;
const SITE_ID       = process.env.SHAREPOINT_SITE_ID;
const LIST_ID       = process.env.SHAREPOINT_STUDENT_CONTENT_LIST_ID;

// ---------------------------------------------------------------------------
// Sample curriculum documents
// Each entry becomes one file in SharePoint with metadata columns set.
// ---------------------------------------------------------------------------

const SAMPLE_DOCS = [
  {
    filename: "Grade5_Math_PlaceValue.txt",
    metadata: { GradeLevel: "5", Subject: "Math", Standard: "5.NBT.A.1", School: "All" },
    content: `PLACE VALUE — GRADE 5

Key Concept: In a multi-digit number, a digit in one place represents 10 times as much as it represents in the place to its right and 1/10 as much as it represents in the place to its left.

LESSON OBJECTIVES
• Read and write decimals to thousandths using base-ten numerals, number names, and expanded form.
• Compare two decimals to thousandths based on meanings of the digits in each place.

VOCABULARY
• Digit: any of the numerals 0–9
• Place value: the value of where a digit is in a number
• Decimal point: the dot that separates the whole number from the fractional part

CORE CONTENT
The place value chart extends in both directions from the ones place:
  Thousands | Hundreds | Tens | Ones . Tenths | Hundredths | Thousandths

Example: 3,456.789
  3 = 3 thousands  (3,000)
  4 = 4 hundreds   (400)
  5 = 5 tens       (50)
  6 = 6 ones       (6)
  7 = 7 tenths     (0.7)
  8 = 8 hundredths (0.08)
  9 = 9 thousandths (0.009)

PATTERN TO REMEMBER
Moving LEFT multiplies the value by 10.
Moving RIGHT divides the value by 10.

PRACTICE PROBLEMS
1. What is the value of the digit 4 in 3,402.15?
2. Write 2.305 in expanded form.
3. Which is greater: 4.072 or 4.27? Explain using place value.
4. A number has 6 in the tenths place, 3 in the ones place, and 0 in the hundredths place. Write the number.

COMMON MISCONCEPTIONS
• Students often think 0.50 > 0.5 — remind them that trailing zeros after the decimal do not change value.
• Students may confuse "tenths" and "tens" — use the place value chart consistently.

REAL-WORLD CONNECTION
Decimals appear in money ($3.75), measurements (1.5 meters), and sports statistics (batting average 0.312).`,
  },
  {
    filename: "Grade5_ELA_TextEvidence.txt",
    metadata: { GradeLevel: "5", Subject: "ELA", Standard: "RI.5.1", School: "All" },
    content: `CITING TEXT EVIDENCE — GRADE 5

Key Concept: When answering questions about a text, support your answer with direct evidence from the text. Do not rely only on background knowledge.

LESSON OBJECTIVES
• Quote accurately from a text when explaining what the text says explicitly.
• Draw inferences from the text and support them with textual evidence.

VOCABULARY
• Evidence: information from the text that supports a claim
• Inference: a conclusion reached by reasoning from evidence
• Quote: the exact words from the text (use quotation marks)
• Paraphrase: restating the author's idea in your own words

SENTENCE STARTERS FOR CITING EVIDENCE
• "According to the text, …"
• "The author states that …"
• "In paragraph ___, it says '…'"
• "This is supported by the detail '…'"
• "The text explains that …"

THE ACE STRATEGY
A — Answer the question directly.
C — Cite evidence from the text (quote or paraphrase).
E — Explain how the evidence supports your answer.

EXAMPLE
Question: Why did the settlers move west?
A: The settlers moved west to find better farmland and new opportunities.
C: According to paragraph 2, "the soil in the east had been worn out by decades of farming."
E: This shows that the poor farming conditions pushed settlers to seek land elsewhere.

PRACTICE QUESTIONS
1. Read the passage and find two pieces of evidence that support the main idea.
2. What inference can you make about the character's feelings? Cite the text.
3. Use the ACE strategy to answer: How does the setting affect the plot?

TIPS FOR STUDENTS
• Always go back to the text before answering.
• Use quotation marks when copying exact words.
• Your evidence should directly connect to your answer — not just be interesting.`,
  },
  {
    filename: "Grade8_Math_LinearEquations.txt",
    metadata: { GradeLevel: "8", Subject: "Math", Standard: "8.EE.C.7", School: "All" },
    content: `LINEAR EQUATIONS IN ONE VARIABLE — GRADE 8

Key Concept: Solve linear equations with rational number coefficients, including equations whose solutions require expanding expressions using the distributive property and collecting like terms.

LESSON OBJECTIVES
• Solve linear equations with one solution, infinitely many solutions, or no solution.
• Identify the number of solutions by analyzing the equation structure.

VOCABULARY
• Linear equation: an equation where the variable has an exponent of 1
• Coefficient: the number multiplied by the variable
• Like terms: terms with the same variable raised to the same power
• Distributive property: a(b + c) = ab + ac
• Solution: the value that makes the equation true

SOLVING STEPS
1. Distribute (remove parentheses if present)
2. Combine like terms on each side
3. Get the variable terms on one side using inverse operations
4. Get the constants on the other side using inverse operations
5. Divide both sides by the coefficient of the variable
6. Check your answer by substituting back into the original equation

WORKED EXAMPLE
Solve: 3(2x − 4) = 2x + 8
Step 1 — Distribute:  6x − 12 = 2x + 8
Step 2 — Subtract 2x: 4x − 12 = 8
Step 3 — Add 12:       4x = 20
Step 4 — Divide by 4:  x = 5
Check: 3(2·5 − 4) = 3(6) = 18 and 2·5 + 8 = 18 ✓

NUMBER OF SOLUTIONS
• One solution: variable terms cancel to a unique value (e.g., x = 5)
• No solution: constants contradict (e.g., 3 = 7) — the equation is inconsistent
• Infinitely many solutions: both sides are identical (e.g., 0 = 0) — all values satisfy it

PRACTICE PROBLEMS
1. Solve: 5x + 3 = 2x + 12
2. Solve: 4(x − 2) = 3x + 1
3. Solve: 2(3x + 1) = 6x + 5  (How many solutions?)
4. Solve: −2(x + 4) = −2x − 8  (How many solutions?)

REAL-WORLD CONNECTION
Linear equations model constant-rate situations: distance = rate × time, cost = price × quantity + fixed fee.`,
  },
  {
    filename: "Grade8_Science_CellBiology.txt",
    metadata: { GradeLevel: "8", Subject: "Science", Standard: "MS-LS1-1", School: "All" },
    content: `CELL STRUCTURE AND FUNCTION — GRADE 8

Key Concept: All living things are made of cells. Cells are the basic structural and functional unit of life. Different cell structures carry out specific functions necessary for the cell's survival.

LESSON OBJECTIVES
• Compare and contrast prokaryotic and eukaryotic cells.
• Identify the function of major cell organelles.
• Explain how structure relates to function in cell organelles.

VOCABULARY
• Cell: the smallest unit of life
• Organelle: a specialized structure within a cell ("little organ")
• Prokaryote: a cell without a membrane-bound nucleus (bacteria)
• Eukaryote: a cell with a membrane-bound nucleus (plants, animals, fungi)
• Membrane: a thin, flexible layer that controls what enters and exits

CELL ORGANELLES AND THEIR FUNCTIONS

Nucleus
• Function: control center; contains DNA (genetic instructions)
• Analogy: the principal's office of the school

Cell Membrane (all cells)
• Function: controls what enters and exits the cell; maintains homeostasis
• Analogy: the school's front door and security desk

Cell Wall (plant cells only)
• Function: rigid outer layer providing structure and protection
• Analogy: the brick walls of the school building

Mitochondria
• Function: produces energy (ATP) through cellular respiration — "powerhouse of the cell"
• Analogy: the school cafeteria providing energy to students

Chloroplasts (plant cells only)
• Function: captures sunlight and converts it to food through photosynthesis
• Analogy: solar panels on the school roof

Ribosomes
• Function: build proteins following instructions from DNA
• Analogy: school workshops where students build projects

Endoplasmic Reticulum (ER)
• Rough ER: has ribosomes; makes and transports proteins
• Smooth ER: no ribosomes; makes lipids and detoxifies chemicals
• Analogy: the school hallways that transport materials

Golgi Apparatus
• Function: packages and ships proteins to their destinations
• Analogy: the school mailroom/post office

Vacuole
• Plant cells: large central vacuole stores water and maintains cell pressure
• Animal cells: small vacuoles store waste and nutrients
• Analogy: storage closets

PROKARYOTE vs EUKARYOTE COMPARISON
| Feature         | Prokaryote      | Eukaryote         |
|----------------|----------------|-------------------|
| Nucleus         | No (DNA free)  | Yes (membrane-bound) |
| Size            | Smaller        | Larger            |
| Organelles      | Few, no membrane| Many, membrane-bound |
| Examples        | Bacteria       | Plants, animals, fungi |

PRACTICE QUESTIONS
1. Which organelle would you expect to find in greater numbers in a muscle cell that needs lots of energy? Explain.
2. A student says plant and animal cells are identical. What two structures would you point to that prove them wrong?
3. Why is the cell membrane important for homeostasis?
4. How does the structure of the mitochondria relate to its function?`,
  },
  {
    filename: "Grade3_Math_Multiplication.txt",
    metadata: { GradeLevel: "3", Subject: "Math", Standard: "3.OA.A.1", School: "All" },
    content: `INTRODUCTION TO MULTIPLICATION — GRADE 3

Key Concept: Multiplication is a way to add equal groups. The product is the total number of objects when you combine equal groups.

LESSON OBJECTIVES
• Interpret multiplication as equal groups (e.g., 3 × 4 = 4 + 4 + 4).
• Use arrays to represent multiplication.
• Know multiplication facts for 0–5 fluently.

VOCABULARY
• Multiplication: combining equal groups to find a total
• Factor: the numbers you multiply (e.g., 3 and 4 in 3 × 4)
• Product: the answer to a multiplication problem
• Array: objects arranged in rows and columns
• Equal groups: groups that have the same number of objects

EQUAL GROUPS MODEL
3 × 4 means "3 groups of 4"
[★★★★]  [★★★★]  [★★★★]
  4         4        4     = 12

ARRAY MODEL
3 × 4 as an array (3 rows, 4 columns):
★ ★ ★ ★
★ ★ ★ ★
★ ★ ★ ★
Count all stars = 12

NUMBER LINE MODEL
3 × 4 on a number line: jump 4 three times
0 →→→→ 4 →→→→ 8 →→→→ 12

MULTIPLICATION PATTERNS
× 0: anything times 0 equals 0 (zero groups means nothing)
× 1: anything times 1 equals itself (one group of the number)
× 2: same as doubling (skip-count by 2s)
× 5: skip-count by 5s; products end in 0 or 5

PRACTICE PROBLEMS
1. Draw equal groups to show 4 × 3. What is the product?
2. Write a multiplication equation for this array: ★★★ / ★★★ / ★★★ / ★★★ / ★★★
3. A baker puts 6 muffins in each box. She fills 4 boxes. How many muffins total?
4. Is 3 × 5 the same as 5 × 3? Draw arrays to show why.

REAL-WORLD CONNECTION
You use multiplication when figuring out how many items are in several equal packages, how many seats are in rows at a theater, or how many legs are on a group of dogs.`,
  },
  {
    filename: "Grade3_ELA_StoryStructure.txt",
    metadata: { GradeLevel: "3", Subject: "ELA", Standard: "RL.3.5", School: "All" },
    content: `STORY STRUCTURE — GRADE 3

Key Concept: Stories have a beginning, middle, and end. Understanding the parts of a story helps readers follow the plot and understand how events connect.

LESSON OBJECTIVES
• Identify the beginning, middle, and end of a story.
• Describe the problem and solution in a story.
• Retell a story using key details in order.

VOCABULARY
• Setting: where and when the story takes place
• Character: the people or animals in the story
• Plot: the events that happen in the story
• Problem (conflict): the challenge the character faces
• Solution (resolution): how the problem is solved
• Sequence: the order in which things happen

PARTS OF A STORY

Beginning
• Introduces the characters and setting
• Presents the problem or conflict
• Questions to ask: Who is in the story? Where does it happen? What is the problem?

Middle
• The character tries to solve the problem
• Events build on each other (rising action)
• Questions to ask: What does the character try? What happens next?

End
• The problem is solved (or not solved)
• The story wraps up
• Questions to ask: How is the problem solved? How does the character feel at the end?

RETELLING A STORY (use these sentence starters)
• "First, …"
• "Next, …"
• "Then, …"
• "After that, …"
• "Finally, …"
• "The problem was … and it was solved when …"

PRACTICE ACTIVITIES
1. Read a short story and fill in a Beginning-Middle-End chart.
2. Draw three pictures showing the beginning, middle, and end.
3. Write two sentences for each part of the story.
4. Identify the problem and solution in the story you read.

TIPS FOR STUDENTS
• A good retelling includes the most important events — not every detail.
• Always include who, what, where, and how the problem was solved.
• Sequence words (first, next, then, finally) help your retelling make sense.`,
  },
];

// ---------------------------------------------------------------------------
// Auth (app-only — service principal has site owner access from provisioning)
// ---------------------------------------------------------------------------

async function getToken() {
  const res = await fetch(
    `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`,
    {
      method: "POST",
      body: new URLSearchParams({
        grant_type:    "client_credentials",
        client_id:     CLIENT_ID,
        client_secret: CLIENT_SECRET,
        scope:         "https://graph.microsoft.com/.default",
      }),
    }
  );
  const data = await res.json();
  if (!data.access_token) throw new Error(`Token error: ${JSON.stringify(data)}`);
  return data.access_token;
}

// ---------------------------------------------------------------------------
// Graph helpers
// ---------------------------------------------------------------------------

async function graph(token, method, path, body, contentType) {
  const res = await fetch(`https://graph.microsoft.com/v1.0${path}`, {
    method,
    headers: {
      Authorization:  `Bearer ${token}`,
      "Content-Type": contentType || "application/json",
    },
    body: body
      ? (contentType ? body : JSON.stringify(body))
      : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Graph ${method} ${path} → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  if (!TENANT_ID || !CLIENT_ID || !CLIENT_SECRET || !SITE_ID || !LIST_ID) {
    console.error("Missing required env vars.");
    process.exit(1);
  }

  console.log("Authenticating...");
  const token = await getToken();

  // Get the drive backing the StudentContent document library.
  console.log("Fetching StudentContent drive...");
  const drive = await graph(token, "GET", `/sites/${SITE_ID}/lists/${LIST_ID}/drive`);
  const driveId = drive.id;
  console.log(`  Drive ID: ${driveId}\n`);

  for (const doc of SAMPLE_DOCS) {
    process.stdout.write(`Uploading ${doc.filename} ... `);

    // 1. Upload the file content to the drive root.
    const fileBytes = Buffer.from(doc.content, "utf-8");
    const uploaded = await graph(
      token,
      "PUT",
      `/drives/${driveId}/root:/${doc.filename}:/content`,
      fileBytes,
      "text/plain"
    );
    const driveItemId = uploaded.id;

    // 2. Fetch the driveItem's sharepointIds (not returned by default on upload).
    const driveItem = await graph(
      token, "GET",
      `/drives/${driveId}/items/${driveItemId}?$select=id,sharepointIds`
    );
    const listItemId = driveItem.sharepointIds?.listItemId;
    if (!listItemId) throw new Error(`No listItemId for ${doc.filename}`);

    // 3. Update the metadata columns.
    await graph(
      token,
      "PATCH",
      `/sites/${SITE_ID}/lists/${LIST_ID}/items/${listItemId}/fields`,
      {
        Title:      doc.filename.replace(".txt", "").replace(/_/g, " "),
        GradeLevel: doc.metadata.GradeLevel,
        Subject:    doc.metadata.Subject,
        Standard:   doc.metadata.Standard,
        School:     doc.metadata.School,
      }
    );

    console.log(`done (item ${listItemId})`);
  }

  console.log(`\n=== Upload complete — ${SAMPLE_DOCS.length} documents added to StudentContent ===`);
  console.log("You can view them at: https://5h1yp7.sharepoint.com/sites/EduAssist/StudentContent");
  console.log("\nEach document is now available for grounding in askCompanion.");
  console.log("Grade coverage: 3, 5, 8 | Subjects: Math, ELA, Science");
}

main().catch(err => {
  console.error("\nFailed:", err.message);
  process.exit(1);
});
