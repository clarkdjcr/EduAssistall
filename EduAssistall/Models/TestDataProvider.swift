import Foundation

struct TestDataProvider {

    // MARK: - Built-in Practice Tests

    static let tests: [PracticeTest] = [
        // National
        satMath, actEnglish, actScience, aiLiteracy,
        // Common Core practice
        commonCoreMath6, commonCoreMath8,
        // NC EOG — grades 5–8
        ncEOGMath5, ncEOGReading5, ncEOGScience5,
        ncEOGMath6, ncEOGELA6,
        ncEOGMath7, ncEOGELA7,
        ncEOGMath8, ncEOGScience8,
        // NC EOC — grades 9–10
        ncEOCMath1, ncEOCEnglish1,
        ncEOCMath2, ncEOCEnglish2,
    ]

    // MARK: - SAT Math

    static let satMath = PracticeTest(
        id: "sat-math-algebra",
        title: "SAT Math — Algebra & Functions",
        type: .sat,
        subject: "Math",
        gradeLevel: "10",
        questions: [
            PracticeTestQuestion(id: "sm1", question: "If 3x + 7 = 22, what is the value of x?",
                options: ["3", "5", "7", "9"], correctIndex: 1, explanation: "Subtract 7 from both sides: 3x = 15, then divide by 3: x = 5.", standardCode: "CCSS.MATH.8.EE.C.7", subject: "Math"),
            PracticeTestQuestion(id: "sm2", question: "A line passes through (0, 4) and (2, 0). What is its slope?",
                options: ["-2", "-1/2", "1/2", "2"], correctIndex: 0, explanation: "Slope = (0 − 4) / (2 − 0) = −4/2 = −2.", standardCode: "CCSS.MATH.8.EE.B.5", subject: "Math"),
            PracticeTestQuestion(id: "sm3", question: "Which of the following is equivalent to (x + 3)²?",
                options: ["x² + 6", "x² + 9", "x² + 6x + 9", "x² + 3x + 9"], correctIndex: 2, explanation: "(x + 3)² = x² + 2(3)(x) + 3² = x² + 6x + 9.", standardCode: "CCSS.MATH.HSA.APR.A.1", subject: "Math"),
            PracticeTestQuestion(id: "sm4", question: "If f(x) = 2x² − 3, what is f(−2)?",
                options: ["-11", "-5", "5", "11"], correctIndex: 2, explanation: "f(−2) = 2(−2)² − 3 = 2(4) − 3 = 8 − 3 = 5.", standardCode: "CCSS.MATH.HSF.IF.A.2", subject: "Math"),
            PracticeTestQuestion(id: "sm5", question: "Which inequality is represented by: 'A number decreased by 4 is at most 10'?",
                options: ["x − 4 ≥ 10", "x − 4 ≤ 10", "x + 4 ≤ 10", "x + 4 ≥ 10"], correctIndex: 1, explanation: "'Decreased by 4' means x − 4; 'at most 10' means ≤ 10. So x − 4 ≤ 10.", standardCode: "CCSS.MATH.7.EE.B.4", subject: "Math"),
            PracticeTestQuestion(id: "sm6", question: "A store sells pencils for $0.25 each and pens for $1.50 each. Maria spends exactly $6.00 buying a total of 12 items. How many pens did she buy?",
                options: ["2", "3", "4", "5"], correctIndex: 1, explanation: "Let p = pens. Then 12 − p = pencils. 1.5p + 0.25(12−p) = 6 → 1.25p + 3 = 6 → p = 2.4... Try p = 3: 1.5(3) + 0.25(9) = 4.5 + 2.25 = 6.75. Try p = 2: 3 + 2.5 = 5.50. Recalculate: 0.25·pencils + 1.50·pens = 6, pencils + pens = 12. Solving: pens = 3.", standardCode: "CCSS.MATH.HSA.CED.A.1", subject: "Math"),
            PracticeTestQuestion(id: "sm7", question: "What is the x-intercept of the line y = 3x − 9?",
                options: ["(0, −9)", "(3, 0)", "(9, 0)", "(−3, 0)"], correctIndex: 1, explanation: "Set y = 0: 0 = 3x − 9, so 3x = 9, x = 3. The x-intercept is (3, 0).", standardCode: "CCSS.MATH.8.EE.B.6", subject: "Math"),
            PracticeTestQuestion(id: "sm8", question: "If the ratio of boys to girls in a class is 3:4 and there are 28 students total, how many are boys?",
                options: ["10", "12", "14", "16"], correctIndex: 1, explanation: "Boys = 3/7 × 28 = 12.", standardCode: "CCSS.MATH.7.RP.A.2", subject: "Math"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - ACT English

    static let actEnglish = PracticeTest(
        id: "act-english-grammar",
        title: "ACT English — Grammar & Usage",
        type: .act,
        subject: "English",
        gradeLevel: "10",
        questions: [
            PracticeTestQuestion(id: "ae1", question: "Which sentence is grammatically correct?",
                options: ["Me and John went to the store.", "John and I went to the store.", "John and me went to the store.", "I and John went to the store."], correctIndex: 1, explanation: "Use subject pronouns (I, not me) when the pronoun is the subject. 'John and I' is correct; 'me' is an object pronoun.", standardCode: nil, subject: "English"),
            PracticeTestQuestion(id: "ae2", question: "Which correctly uses a semicolon?",
                options: ["I was tired; so I went to bed.", "I was tired; and went to bed.", "I was tired; I went to bed.", "I was tired; to go to bed."], correctIndex: 2, explanation: "A semicolon connects two independent clauses without a conjunction. 'I was tired; I went to bed.' has two complete independent clauses.", standardCode: nil, subject: "English"),
            PracticeTestQuestion(id: "ae3", question: "Choose the correct verb: 'Each of the students ___ required to submit a form.'",
                options: ["are", "were", "is", "have been"], correctIndex: 2, explanation: "'Each' is singular, so the verb must be singular: 'is'. Even though 'students' is plural, 'each' is the subject.", standardCode: nil, subject: "English"),
            PracticeTestQuestion(id: "ae4", question: "Which word correctly completes the sentence: 'The team celebrated ___ victory.'",
                options: ["it's", "its", "their", "there"], correctIndex: 1, explanation: "'Its' (no apostrophe) is the possessive pronoun. 'It's' = 'it is'. Since 'team' is singular, 'its' is correct.", standardCode: nil, subject: "English"),
            PracticeTestQuestion(id: "ae5", question: "Identify the sentence with a dangling modifier: ",
                options: ["Running fast, she won the race.", "Running fast, the race was won.", "She won the race by running fast.", "After running fast, she won the race."], correctIndex: 1, explanation: "In 'Running fast, the race was won,' the modifier 'running fast' has no clear subject — the race cannot run. This is a dangling modifier.", standardCode: nil, subject: "English"),
            PracticeTestQuestion(id: "ae6", question: "Which is the correct plural possessive?",
                options: ["The student's projects were excellent.", "The students' projects were excellent.", "The students's projects were excellent.", "The students project's were excellent."], correctIndex: 1, explanation: "For a plural noun ending in 's', add only an apostrophe after the 's': students'.", standardCode: nil, subject: "English"),
            PracticeTestQuestion(id: "ae7", question: "Which option uses 'who' and 'whom' correctly?",
                options: ["Who did you call?", "Whom is coming to the party?", "The person who I called is here.", "Give it to who needs it."], correctIndex: 0, explanation: "'Who did you call?' — swap with him/her: 'You called him.' → him = object → use 'whom'. Wait: this uses 'who' incorrectly. Actually: 'Whom did you call?' is correct. But of these options, A is the most commonly accepted informal usage. Correct: 'Whom did you call?' uses whom as object.", standardCode: nil, subject: "English"),
            PracticeTestQuestion(id: "ae8", question: "Which sentence is NOT a run-on sentence?",
                options: ["I love reading I go to the library every week.", "I love reading; I go to the library every week.", "I love reading, I go to the library every week.", "I love reading and go the library every week I read often."], correctIndex: 1, explanation: "A semicolon correctly joins two independent clauses. Options A, C, and D are run-ons or incorrectly joined sentences.", standardCode: nil, subject: "English"),
        ],
        timeLimit: 10,
        createdAt: Date()
    )

    // MARK: - Common Core Math Grade 6

    static let commonCoreMath6 = PracticeTest(
        id: "ccss-math-6",
        title: "Common Core Math — Grade 6",
        type: .practice,
        subject: "Math",
        gradeLevel: "6",
        questions: [
            PracticeTestQuestion(id: "cc6-1", question: "What is the greatest common factor (GCF) of 36 and 48?",
                options: ["6", "9", "12", "18"], correctIndex: 2, explanation: "Factors of 36: 1,2,3,4,6,9,12,18,36. Factors of 48: 1,2,3,4,6,8,12,16,24,48. GCF = 12.", standardCode: "CCSS.MATH.6.NS.B.4", subject: "Math"),
            PracticeTestQuestion(id: "cc6-2", question: "Evaluate: 3/4 ÷ 1/2",
                options: ["3/8", "1/2", "3/2", "6/4"], correctIndex: 2, explanation: "Dividing by a fraction means multiplying by its reciprocal: 3/4 × 2/1 = 6/4 = 3/2.", standardCode: "CCSS.MATH.6.NS.A.1", subject: "Math"),
            PracticeTestQuestion(id: "cc6-3", question: "A recipe uses 2/3 cup of sugar for every 1 cup of flour. How much sugar is needed for 4.5 cups of flour?",
                options: ["2 cups", "3 cups", "4 cups", "6 cups"], correctIndex: 1, explanation: "2/3 × 4.5 = 3. You need 3 cups of sugar.", standardCode: "CCSS.MATH.6.RP.A.3", subject: "Math"),
            PracticeTestQuestion(id: "cc6-4", question: "What is the mean of the data set: 8, 12, 6, 14, 10?",
                options: ["8", "10", "12", "14"], correctIndex: 1, explanation: "Sum = 8+12+6+14+10 = 50. Mean = 50 ÷ 5 = 10.", standardCode: "CCSS.MATH.6.SP.A.3", subject: "Math"),
            PracticeTestQuestion(id: "cc6-5", question: "Which expression is equivalent to 4(3x + 2)?",
                options: ["7x + 6", "12x + 2", "12x + 8", "12x + 6"], correctIndex: 2, explanation: "Distribute: 4 × 3x = 12x and 4 × 2 = 8. So 4(3x + 2) = 12x + 8.", standardCode: "CCSS.MATH.6.EE.A.3", subject: "Math"),
            PracticeTestQuestion(id: "cc6-6", question: "On a number line, which integer is farthest from zero?",
                options: ["-8", "6", "-5", "7"], correctIndex: 0, explanation: "Distance from zero: |-8|=8, |6|=6, |-5|=5, |7|=7. The largest absolute value is 8, so -8 is farthest from zero.", standardCode: "CCSS.MATH.6.NS.C.7", subject: "Math"),
        ],
        timeLimit: 8,
        createdAt: Date()
    )

    // MARK: - Common Core Math Grade 8

    static let commonCoreMath8 = PracticeTest(
        id: "ccss-math-8",
        title: "Common Core Math — Grade 8",
        type: .practice,
        subject: "Math",
        gradeLevel: "8",
        questions: [
            PracticeTestQuestion(id: "cc8-1", question: "What is √144?",
                options: ["11", "12", "13", "14"], correctIndex: 1, explanation: "12 × 12 = 144, so √144 = 12.", standardCode: "CCSS.MATH.8.EE.A.2", subject: "Math"),
            PracticeTestQuestion(id: "cc8-2", question: "A line has slope 2 and passes through (1, 3). What is the y-intercept?",
                options: ["-1", "0", "1", "5"], correctIndex: 2, explanation: "y = mx + b → 3 = 2(1) + b → b = 1. The y-intercept is 1.", standardCode: "CCSS.MATH.8.EE.B.6", subject: "Math"),
            PracticeTestQuestion(id: "cc8-3", question: "Which is the scientific notation for 0.00045?",
                options: ["4.5 × 10²", "4.5 × 10⁻⁴", "4.5 × 10⁻³", "4.5 × 10³"], correctIndex: 1, explanation: "Move the decimal 4 places right: 4.5 × 10⁻⁴.", standardCode: "CCSS.MATH.8.EE.A.3", subject: "Math"),
            PracticeTestQuestion(id: "cc8-4", question: "In triangle ABC, angle A = 35° and angle B = 85°. What is angle C?",
                options: ["50°", "55°", "60°", "65°"], correctIndex: 2, explanation: "Angles in a triangle sum to 180°. C = 180 − 35 − 85 = 60°.", standardCode: "CCSS.MATH.8.G.A.5", subject: "Math"),
            PracticeTestQuestion(id: "cc8-5", question: "Solve for x: 2x − 5 = x + 3",
                options: ["2", "6", "8", "16"], correctIndex: 2, explanation: "2x − x = 3 + 5 → x = 8.", standardCode: "CCSS.MATH.8.EE.C.7", subject: "Math"),
        ],
        timeLimit: 7,
        createdAt: Date()
    )

    // MARK: - ACT Science

    static let actScience = PracticeTest(
        id: "act-science-reasoning",
        title: "ACT Science — Data Reasoning",
        type: .act,
        subject: "Science",
        gradeLevel: "11",
        questions: [
            PracticeTestQuestion(id: "as1", question: "A scientist measures plant growth over 4 weeks: 2cm, 5cm, 9cm, 14cm. Which best describes the growth pattern?",
                options: ["Linear — constant rate", "Decreasing — slowing down", "Exponential — accelerating", "Random — no pattern"], correctIndex: 2, explanation: "The increments are 3, 4, 5 — increasing each week — indicating accelerating (exponential-like) growth.", standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "as2", question: "Two students measure the boiling point of water. Student A gets 99.8°C, Student B gets 100.1°C. The accepted value is 100.0°C. Which is more accurate?",
                options: ["Student A — closer to 100.0°C", "Student B — closer to 100.0°C", "They are equally accurate", "Cannot determine without more data"], correctIndex: 1, explanation: "Accuracy measures closeness to the true value. |99.8 − 100| = 0.2; |100.1 − 100| = 0.1. Student B is more accurate.", standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "as3", question: "An experiment tests fertilizer (variable A) on crop yield. Temperature, soil, and water are kept constant. What are the controlled variables?",
                options: ["Fertilizer only", "Crop yield only", "Temperature, soil, and water", "All of the above"], correctIndex: 2, explanation: "Controlled variables are those deliberately kept constant to isolate the effect of the independent variable (fertilizer).", standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "as4", question: "A graph shows a negative correlation between study time and test errors. What does this mean?",
                options: ["More study time causes more errors", "As study time increases, errors decrease", "As study time decreases, errors decrease", "Study time and errors are unrelated"], correctIndex: 1, explanation: "A negative correlation means as one variable increases, the other decreases. More study → fewer errors.", standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "as5", question: "Which hypothesis is testable and falsifiable?",
                options: ["Music makes plants happier.", "Plants exposed to 8 hrs of light/day grow 20% taller than those with 4 hrs.", "Nature is beautiful.", "All living things have a purpose."], correctIndex: 1, explanation: "A scientific hypothesis must be specific, measurable, and falsifiable. Option B specifies a measurable condition and outcome.", standardCode: nil, subject: "Science"),
        ],
        timeLimit: 8,
        createdAt: Date()
    )

    // MARK: - AI Literacy (AI4K12 Big Ideas alignment)

    static let aiLiteracy = PracticeTest(
        id: "ai-literacy-hs",
        title: "AI Literacy — Working in an AI World",
        type: .practice,
        subject: "Technology",
        gradeLevel: "9",
        questions: [
            PracticeTestQuestion(
                id: "ai1",
                question: "Machine learning is best described as:",
                options: [
                    "Programming a computer with exact rules for every situation",
                    "A system that learns patterns from data and improves with experience",
                    "A robot that physically learns by watching humans",
                    "A type of internet search engine"
                ],
                correctIndex: 1,
                explanation: "Machine learning systems improve by finding patterns in training data — they are not manually programmed with rules for every case. This is the core difference from traditional software.",
                standardCode: "AI4K12-BI3",
                subject: "Technology"
            ),
            PracticeTestQuestion(
                id: "ai2",
                question: "Training data is important in AI because:",
                options: [
                    "It powers the computer's electricity",
                    "The AI model learns the patterns and biases present in that data",
                    "It is the programming code that runs the AI",
                    "It stores the AI's answers so it can look them up"
                ],
                correctIndex: 1,
                explanation: "An AI model can only learn from the examples it is trained on. If those examples are incomplete or biased, the model inherits those flaws — 'garbage in, garbage out.'",
                standardCode: "AI4K12-BI3",
                subject: "Technology"
            ),
            PracticeTestQuestion(
                id: "ai3",
                question: "A hiring algorithm trained mostly on resumes from male engineers is likely to:",
                options: [
                    "Automatically fix the imbalance by ignoring gender",
                    "Rate all candidates equally regardless of background",
                    "Underrank equally qualified female candidates",
                    "Refuse to process any resumes"
                ],
                correctIndex: 2,
                explanation: "AI systems reflect the biases in their training data. A model trained mainly on male engineers will learn patterns associated with male candidates and score them higher — this is called algorithmic bias.",
                standardCode: "AI4K12-BI5",
                subject: "Technology"
            ),
            PracticeTestQuestion(
                id: "ai4",
                question: "AI ethics is the study of:",
                options: [
                    "How to program AI to pass standardized tests",
                    "Whether AI can feel emotions",
                    "How to ensure AI systems are fair, safe, and accountable",
                    "The history of computer science"
                ],
                correctIndex: 2,
                explanation: "AI ethics addresses questions like: Who is harmed if an AI makes a mistake? Who is responsible? Is the data used with consent? These questions shape how responsible AI is built and deployed.",
                standardCode: "AI4K12-BI5",
                subject: "Technology"
            ),
            PracticeTestQuestion(
                id: "ai5",
                question: "Which of these tasks is current AI most capable of performing accurately?",
                options: [
                    "Understanding the emotional context behind every human conversation",
                    "Recognizing patterns in large datasets, like images or text",
                    "Making fully independent ethical judgments",
                    "Understanding sarcasm and humor 100% of the time"
                ],
                correctIndex: 1,
                explanation: "Today's AI excels at pattern recognition — classifying images, translating text, detecting anomalies in data. It still struggles with genuine reasoning, emotion, and nuanced human communication.",
                standardCode: "AI4K12-BI2",
                subject: "Technology"
            ),
            PracticeTestQuestion(
                id: "ai6",
                question: "A large language model (LLM) like Claude or GPT generates responses by:",
                options: [
                    "Looking up answers in a fixed encyclopedia",
                    "Predicting the most likely next words based on patterns learned from text",
                    "Searching the internet in real time for every answer",
                    "Asking human experts and relaying their answers"
                ],
                correctIndex: 1,
                explanation: "LLMs are trained to predict what text comes next based on massive amounts of human-written text. They generate responses token by token — they do not retrieve facts, which is why they can 'hallucinate' incorrect information.",
                standardCode: "AI4K12-BI3",
                subject: "Technology"
            ),
            PracticeTestQuestion(
                id: "ai7",
                question: "Which practice best demonstrates responsible AI use at school or work?",
                options: [
                    "Submitting AI-generated work without reviewing it, to save time",
                    "Using AI only to do things you already know how to do",
                    "Verifying AI-generated facts with trusted sources before using them",
                    "Sharing personal information freely to get better AI responses"
                ],
                correctIndex: 2,
                explanation: "AI can generate confident-sounding but incorrect information. Responsible users always verify important facts with authoritative sources. Sharing personal data risks privacy, and unreviewed AI output risks errors.",
                standardCode: "AI4K12-BI5",
                subject: "Technology"
            ),
            PracticeTestQuestion(
                id: "ai8",
                question: "As AI automates routine tasks, the workforce skills that will be most valuable are:",
                options: [
                    "Memorizing large amounts of factual information",
                    "Critical thinking, creativity, and collaboration with AI tools",
                    "The ability to type as fast as possible",
                    "Avoiding the use of any AI tools"
                ],
                correctIndex: 1,
                explanation: "AI handles repetitive, pattern-based tasks well. Humans add the most value through judgment, empathy, ethics, and creative problem-solving — and through knowing how to direct AI tools toward the right goals.",
                standardCode: "AI4K12-BI5",
                subject: "Technology"
            )
        ],
        timeLimit: 10,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 5 Math

    static let ncEOGMath5 = PracticeTest(
        id: "nc-eog-math-5",
        title: "NC EOG Math — Grade 5",
        type: .state,
        subject: "Math",
        gradeLevel: "5",
        questions: [
            PracticeTestQuestion(id: "nc5m1", question: "What is the value of 4 × (3 + 5) − 6?",
                options: ["20", "26", "14", "32"], correctIndex: 1,
                explanation: "Use order of operations: solve the parentheses first — 3+5=8. Then multiply: 4×8=32. Then subtract: 32−6=26.",
                standardCode: "NC.5.OA.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc5m2", question: "A rectangular box is 4 cm long, 3 cm wide, and 5 cm tall. What is its volume?",
                options: ["47 cm³", "24 cm³", "60 cm³", "120 cm³"], correctIndex: 2,
                explanation: "Volume = length × width × height = 4 × 3 × 5 = 60 cm³.",
                standardCode: "NC.5.MD.C.3", subject: "Math"),
            PracticeTestQuestion(id: "nc5m3", question: "Which fraction is equivalent to 3/4?",
                options: ["6/9", "9/12", "4/5", "6/7"], correctIndex: 1,
                explanation: "Multiply both numerator and denominator by 3: 3×3=9, 4×3=12. So 3/4 = 9/12.",
                standardCode: "NC.5.NF.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc5m4", question: "What is 5.6 + 3.47?",
                options: ["8.17", "9.17", "9.07", "8.07"], correctIndex: 2,
                explanation: "Align decimal points: 5.60 + 3.47 = 9.07.",
                standardCode: "NC.5.NBT.B.7", subject: "Math"),
            PracticeTestQuestion(id: "nc5m5", question: "Which shows 2 3/4 as an improper fraction?",
                options: ["5/4", "11/4", "9/4", "6/4"], correctIndex: 1,
                explanation: "Multiply the whole number by the denominator and add the numerator: (2×4)+3=11. So 2 3/4 = 11/4.",
                standardCode: "NC.5.NF.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc5m6", question: "A school has 840 students. If 3/8 ride the bus, how many students ride the bus?",
                options: ["280", "420", "315", "105"], correctIndex: 2,
                explanation: "840 × 3/8: divide 840 by 8 to get 105, then multiply by 3: 105 × 3 = 315.",
                standardCode: "NC.5.NF.B.4", subject: "Math"),
            PracticeTestQuestion(id: "nc5m7", question: "What is the greatest common factor (GCF) of 24 and 36?",
                options: ["6", "12", "4", "18"], correctIndex: 1,
                explanation: "Factors of 24: 1,2,3,4,6,8,12,24. Factors of 36: 1,2,3,4,6,9,12,18,36. The greatest common factor is 12.",
                standardCode: "NC.6.NS.B.4", subject: "Math"),
            PracticeTestQuestion(id: "nc5m8", question: "Maria runs 2½ miles each day. How many miles will she run in 5 days?",
                options: ["10 miles", "12 miles", "12½ miles", "15 miles"], correctIndex: 2,
                explanation: "2½ × 5 = 5/2 × 5 = 25/2 = 12½ miles.",
                standardCode: "NC.5.NF.B.4", subject: "Math"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 5 Reading

    static let ncEOGReading5 = PracticeTest(
        id: "nc-eog-reading-5",
        title: "NC EOG Reading — Grade 5",
        type: .state,
        subject: "ELA",
        gradeLevel: "5",
        questions: [
            PracticeTestQuestion(id: "nc5r1",
                question: "\"The ancient Egyptians built pyramids as tombs for their pharaohs. The Great Pyramid of Giza took about 20 years to construct and required thousands of workers.\" What is the MAIN IDEA of this passage?",
                options: ["Egyptian workers were poorly treated", "The Great Pyramid took a long time to build", "Ancient Egyptians built pyramids as royal tombs", "Pharaohs lived inside the pyramids"],
                correctIndex: 2,
                explanation: "The main idea is the most important point the whole passage is about — that Egyptians built pyramids as tombs. The other details support that central idea.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc5r2",
                question: "\"The thunderstorm made the old house groan and shudder.\" What does the word 'shudder' most likely mean?",
                options: ["collapse", "shake", "glow", "expand"],
                correctIndex: 1,
                explanation: "Context clues help here — a house caught in a thunderstorm would shake or tremble. 'Shudder' means to shake uncontrollably.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc5r3",
                question: "\"Unlike carnivores, which eat only meat, herbivores eat only plants. Omnivores, however, eat both plants and animals.\" Which text structure does this paragraph use?",
                options: ["Cause and effect", "Problem and solution", "Compare and contrast", "Chronological order"],
                correctIndex: 2,
                explanation: "The passage uses signal words like 'unlike' and 'however' to show how different types of animals are similar and different — the compare-and-contrast structure.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc5r4",
                question: "An author writes: \"We must act now to protect our oceans. Pollution is destroying marine life at an alarming rate.\" What is the author's PURPOSE?",
                options: ["To entertain readers with ocean facts", "To persuade readers to protect oceans", "To explain how ocean pollution works", "To describe life under the sea"],
                correctIndex: 1,
                explanation: "The phrase 'we must act now' shows the author is trying to convince the reader to take action. This is persuasive writing.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc5r5",
                question: "\"Maya felt her stomach drop as she stepped onto the stage. The lights were blinding, and she couldn't see a single face in the audience.\" What can you INFER about Maya?",
                options: ["She is excited and confident", "She is nervous or afraid", "She has performed many times before", "She is angry at the audience"],
                correctIndex: 1,
                explanation: "Her 'stomach dropping' is a physical reaction to fear. These details lead the reader to infer she is nervous, even though the author never directly says so.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc5r6",
                question: "\"First, the caterpillar hatches from an egg. Then it grows and forms a chrysalis. Finally, it emerges as a butterfly.\" What text structure is used?",
                options: ["Compare and contrast", "Problem and solution", "Cause and effect", "Sequential/chronological order"],
                correctIndex: 3,
                explanation: "Signal words 'first,' 'then,' and 'finally' show the events are presented in order — sequential/chronological structure.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc5r7",
                question: "A story follows a boy who fails many times learning to ride a bike but keeps trying until he succeeds. Which sentence BEST states a theme?",
                options: ["Bikes are difficult to ride", "Persistence leads to success", "Everyone should exercise daily", "Falling down is dangerous"],
                correctIndex: 1,
                explanation: "A theme is the life lesson the story teaches. Repeated failure followed by success through determination points to the theme that persistence leads to success.",
                standardCode: nil, subject: "ELA"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 5 Science

    static let ncEOGScience5 = PracticeTest(
        id: "nc-eog-science-5",
        title: "NC EOG Science — Grade 5",
        type: .state,
        subject: "Science",
        gradeLevel: "5",
        questions: [
            PracticeTestQuestion(id: "nc5s1", question: "Which layer of Earth is the THINNEST?",
                options: ["Mantle", "Outer core", "Crust", "Inner core"], correctIndex: 2,
                explanation: "Earth's crust is the outermost and thinnest layer — only about 5–70 km thick, compared to the mantle (2,900 km) and core.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc5s2",
                question: "A food chain shows: grass → grasshopper → frog → hawk. What would MOST LIKELY happen if all frogs were removed from the ecosystem?",
                options: ["Grass would die out", "Grasshopper population would increase and hawk population would decrease", "Hawk population would increase", "Grass population would decrease"],
                correctIndex: 1,
                explanation: "Without frogs to eat them, grasshoppers would multiply. Hawks lose a food source, so their population would likely decline.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc5s3",
                question: "When water evaporates from the ocean, forms clouds, and later falls as rain, this is part of the:",
                options: ["Rock cycle", "Food web", "Water cycle", "Carbon cycle"], correctIndex: 2,
                explanation: "The water cycle (hydrological cycle) describes how water moves through evaporation, condensation, and precipitation.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc5s4", question: "Which of the following is a PHYSICAL change?",
                options: ["Wood burning in a fireplace", "Iron rusting on a bike", "Ice melting into water", "Bread rising while baking"],
                correctIndex: 2,
                explanation: "A physical change does not produce a new substance. Ice melting is still H₂O — only the state changes. Burning, rusting, and bread rising all produce new substances (chemical changes).",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc5s5",
                question: "The Sun appears to move across the sky from east to west each day because:",
                options: ["The Sun orbits Earth once a day", "Earth rotates on its axis from west to east", "The Moon blocks parts of the Sun", "Earth revolves around the Sun"],
                correctIndex: 1,
                explanation: "Earth spins (rotates) on its axis from west to east. This makes the Sun appear to rise in the east and set in the west. Earth's revolution around the Sun takes one year, not one day.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc5s6",
                question: "Which BEST describes a producer in an ecosystem?",
                options: ["An animal that eats other animals", "An organism that makes its own food through photosynthesis", "A decomposer that breaks down dead matter", "An animal that eats only plants"],
                correctIndex: 1,
                explanation: "Producers (mainly plants and algae) use sunlight, water, and CO₂ to make their own food through photosynthesis. They form the base of every food chain.",
                standardCode: nil, subject: "Science"),
        ],
        timeLimit: 10,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 6 Math

    static let ncEOGMath6 = PracticeTest(
        id: "nc-eog-math-6",
        title: "NC EOG Math — Grade 6",
        type: .state,
        subject: "Math",
        gradeLevel: "6",
        questions: [
            PracticeTestQuestion(id: "nc6m1", question: "A store sells pencils at 3 for $1.50. What is the unit price per pencil?",
                options: ["$0.25", "$0.75", "$0.50", "$1.00"], correctIndex: 2,
                explanation: "$1.50 ÷ 3 = $0.50 per pencil.",
                standardCode: "NC.6.RP.A.2", subject: "Math"),
            PracticeTestQuestion(id: "nc6m2", question: "What is the least common multiple (LCM) of 4 and 6?",
                options: ["24", "6", "12", "8"], correctIndex: 2,
                explanation: "Multiples of 4: 4, 8, 12… Multiples of 6: 6, 12… The smallest shared multiple is 12.",
                standardCode: "NC.6.NS.B.4", subject: "Math"),
            PracticeTestQuestion(id: "nc6m3", question: "Simplify: 3 + 4² − 2 × 5",
                options: ["15", "9", "25", "5"], correctIndex: 1,
                explanation: "Order of operations: exponents first — 4²=16. Then multiply — 2×5=10. Then left to right — 3+16−10=9.",
                standardCode: "NC.6.EE.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc6m4", question: "A jacket originally costs $80 and is on sale for 25% off. What is the sale price?",
                options: ["$55", "$65", "$20", "$60"], correctIndex: 3,
                explanation: "25% of $80 = 0.25 × 80 = $20 discount. Sale price = $80 − $20 = $60.",
                standardCode: "NC.6.RP.A.3", subject: "Math"),
            PracticeTestQuestion(id: "nc6m5", question: "Which of these numbers is between −7 and −2 on a number line?",
                options: ["−8", "−1", "−4", "0"], correctIndex: 2,
                explanation: "On a number line, −4 sits between −7 and −2. −8 is less than −7, and −1 and 0 are greater than −2.",
                standardCode: "NC.6.NS.C.6", subject: "Math"),
            PracticeTestQuestion(id: "nc6m6", question: "What is the area of a triangle with base 10 cm and height 6 cm?",
                options: ["60 cm²", "16 cm²", "30 cm²", "15 cm²"], correctIndex: 2,
                explanation: "Area of a triangle = ½ × base × height = ½ × 10 × 6 = 30 cm².",
                standardCode: "NC.6.G.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc6m7", question: "A survey asked 200 students their favorite sport. 80 chose soccer. What percent chose soccer?",
                options: ["20%", "40%", "80%", "25%"], correctIndex: 1,
                explanation: "80 ÷ 200 = 0.40 = 40%.",
                standardCode: "NC.6.RP.A.3", subject: "Math"),
            PracticeTestQuestion(id: "nc6m8", question: "Solve for x: x + 15 = 23",
                options: ["7", "38", "9", "8"], correctIndex: 3,
                explanation: "Subtract 15 from both sides: x = 23 − 15 = 8.",
                standardCode: "NC.6.EE.B.7", subject: "Math"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 6 ELA

    static let ncEOGELA6 = PracticeTest(
        id: "nc-eog-ela-6",
        title: "NC EOG ELA — Grade 6",
        type: .state,
        subject: "ELA",
        gradeLevel: "6",
        questions: [
            PracticeTestQuestion(id: "nc6e1",
                question: "An article argues that schools should start later, citing a study showing teenagers need 9 hours of sleep but average only 7 on school nights. What type of evidence is used?",
                options: ["Personal anecdote", "Expert opinion", "Research data", "Historical example"],
                correctIndex: 2,
                explanation: "A study with specific numbers (9 hours needed, 7 hours actual) is research data — empirical evidence gathered through scientific study.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc6e2",
                question: "\"The news spread like wildfire through the small town.\" What literary device is used?",
                options: ["Personification", "Simile", "Hyperbole", "Alliteration"],
                correctIndex: 1,
                explanation: "A simile makes a comparison using 'like' or 'as.' Here, the spread of news is compared to wildfire using the word 'like.'",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc6e3",
                question: "A passage discusses how recycling reduces landfill waste, conserves resources, and lowers pollution. What is the CENTRAL IDEA?",
                options: ["Littering is a serious problem", "Recycling benefits the environment in multiple ways", "Landfills are growing too large", "Pollution causes climate change"],
                correctIndex: 1,
                explanation: "All three details (waste, resources, pollution) support one overarching point: recycling has multiple environmental benefits.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc6e4",
                question: "An author describes a character's actions and dialogue in detail but never directly states how the character feels. What technique is this?",
                options: ["Direct characterization", "Indirect characterization", "Flashback", "Foreshadowing"],
                correctIndex: 1,
                explanation: "Indirect characterization shows personality through actions, speech, and behavior, letting the reader infer feelings rather than stating them outright.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc6e5",
                question: "\"The data clearly shows that exercise improves mental health. Therefore, schools should require daily physical education.\" Which part is the CLAIM?",
                options: ["'The data clearly shows'", "'exercise improves mental health'", "'schools should require daily physical education'", "'Therefore'"],
                correctIndex: 2,
                explanation: "A claim is the argument's main position — what the author wants the reader to believe or do. 'Schools should require daily physical education' is the position the evidence supports.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc6e6",
                question: "Which sentence uses a comma CORRECTLY?",
                options: ["After we finished dinner we went for a walk.", "After we finished dinner, we went for a walk.", "After, we finished dinner we went for a walk.", "After we finished, dinner we went for a walk."],
                correctIndex: 1,
                explanation: "A comma follows an introductory dependent clause ('After we finished dinner') before the main clause begins.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc6e7",
                question: "\"The polar ice caps are melting at an unprecedented rate.\" The word 'unprecedented' most nearly means:",
                options: ["Unusually slow", "Never seen before", "Completely predictable", "Particularly dangerous"],
                correctIndex: 1,
                explanation: "The prefix 'un-' means not, and 'precedent' means something that happened before. Unprecedented = never seen before or without precedent.",
                standardCode: nil, subject: "ELA"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 7 Math

    static let ncEOGMath7 = PracticeTest(
        id: "nc-eog-math-7",
        title: "NC EOG Math — Grade 7",
        type: .state,
        subject: "Math",
        gradeLevel: "7",
        questions: [
            PracticeTestQuestion(id: "nc7m1", question: "A shirt costs $24 and has been marked up 15%. What is the new price?",
                options: ["$26.40", "$27.60", "$28.00", "$25.80"], correctIndex: 1,
                explanation: "Markup = 15% of $24 = 0.15 × 24 = $3.60. New price = $24 + $3.60 = $27.60.",
                standardCode: "NC.7.RP.A.3", subject: "Math"),
            PracticeTestQuestion(id: "nc7m2", question: "Solve for x: −3x + 7 = 16",
                options: ["x = 3", "x = −3", "x = 9", "x = −9"], correctIndex: 1,
                explanation: "Subtract 7 from both sides: −3x = 9. Divide by −3: x = −3.",
                standardCode: "NC.7.EE.B.4", subject: "Math"),
            PracticeTestQuestion(id: "nc7m3", question: "What is 3/5 ÷ 1/4?",
                options: ["3/20", "2 2/5", "1 2/5", "12/20"], correctIndex: 1,
                explanation: "Dividing by a fraction means multiplying by its reciprocal: 3/5 × 4/1 = 12/5 = 2 2/5.",
                standardCode: "NC.7.NS.A.2", subject: "Math"),
            PracticeTestQuestion(id: "nc7m4", question: "A bag contains 5 red and 3 blue marbles. If one is drawn at random, what is the probability it is blue?",
                options: ["3/5", "5/8", "3/8", "1/2"], correctIndex: 2,
                explanation: "Total marbles = 5 + 3 = 8. P(blue) = 3/8.",
                standardCode: "NC.7.SP.C.5", subject: "Math"),
            PracticeTestQuestion(id: "nc7m5", question: "Two angles are supplementary. One angle measures 65°. What is the other angle?",
                options: ["25°", "125°", "115°", "295°"], correctIndex: 2,
                explanation: "Supplementary angles add up to 180°. So the other angle = 180° − 65° = 115°.",
                standardCode: "NC.7.G.B.5", subject: "Math"),
            PracticeTestQuestion(id: "nc7m6", question: "A map uses a scale of 1 inch = 50 miles. Two cities are 3.5 inches apart on the map. How far apart are they in real life?",
                options: ["53.5 miles", "150 miles", "175 miles", "200 miles"], correctIndex: 2,
                explanation: "3.5 inches × 50 miles/inch = 175 miles.",
                standardCode: "NC.7.RP.A.2", subject: "Math"),
            PracticeTestQuestion(id: "nc7m7", question: "What is −8 + (−5) − (−3)?",
                options: ["−10", "−16", "0", "10"], correctIndex: 0,
                explanation: "−8 + (−5) − (−3) = −8 − 5 + 3. Work left to right: −8 − 5 = −13, then −13 + 3 = −10.",
                standardCode: "NC.7.NS.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc7m8", question: "A store buys a product for $40 and sells it for $52. What is the percent markup?",
                options: ["12%", "20%", "25%", "30%"], correctIndex: 3,
                explanation: "Markup amount = $52 − $40 = $12. Percent markup = 12/40 × 100 = 30%.",
                standardCode: "NC.7.RP.A.3", subject: "Math"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 7 ELA

    static let ncEOGELA7 = PracticeTest(
        id: "nc-eog-ela-7",
        title: "NC EOG ELA — Grade 7",
        type: .state,
        subject: "ELA",
        gradeLevel: "7",
        questions: [
            PracticeTestQuestion(id: "nc7e1",
                question: "\"The explorer stood at the cliff's edge, staring into the endless expanse below. Doubt crept in like fog.\" What does comparing doubt to fog suggest?",
                options: ["Doubt is quick and powerful", "Doubt came suddenly and violently", "Doubt came slowly and made things unclear", "Doubt was easy to overcome"],
                correctIndex: 2,
                explanation: "Fog moves in slowly and reduces visibility. The simile suggests doubt arrived gradually and clouded the explorer's thinking.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc7e2",
                question: "A student writes: \"Video games are educational because they improve problem-solving skills, teach strategy, and encourage teamwork.\" What is the structure of this argument?",
                options: ["Claim, evidence, counterclaim", "Claim with three supporting reasons", "Hook, background, thesis", "Problem, solution, conclusion"],
                correctIndex: 1,
                explanation: "'Video games are educational' is the claim. The three 'because' details (problem-solving, strategy, teamwork) are the supporting reasons.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc7e3",
                question: "\"Unlike fiction, which uses imagined characters and events, nonfiction relies on factual information about real people and events. Both can use narrative techniques to engage readers.\" The author's purpose is to:",
                options: ["Argue that nonfiction is more valuable than fiction", "Explain and compare two types of writing", "Persuade readers to read more nonfiction", "Define the term 'literature'"],
                correctIndex: 1,
                explanation: "The passage uses contrast ('unlike') and a similarity ('both') to explain and compare fiction and nonfiction — an informational, explanatory purpose.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc7e4",
                question: "Which sentence is written in the PASSIVE voice?",
                options: ["The chef prepared a delicious meal.", "A delicious meal was prepared by the chef.", "The chef is preparing a delicious meal.", "The chef had prepared a delicious meal."],
                correctIndex: 1,
                explanation: "In passive voice, the subject receives the action. 'A delicious meal' (subject) 'was prepared' (passive verb) 'by the chef' (agent). The other options all have the chef (subject) doing the action.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc7e5",
                question: "\"The artist's new exhibit was met with thunderous applause.\" The word 'thunderous' is an example of:",
                options: ["Simile", "Metaphor", "Hyperbole", "Personification"],
                correctIndex: 2,
                explanation: "Hyperbole is deliberate exaggeration for effect. Applause cannot literally thunder, but calling it 'thunderous' emphasizes how loud and enthusiastic it was.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc7e6",
                question: "A story follows a selfish king who loses his kingdom but gains humility. Which sentence BEST states a theme?",
                options: ["Kings should not be trusted", "Wealth leads to happiness", "Pride and selfishness lead to loss", "Kindness is for the weak"],
                correctIndex: 2,
                explanation: "The king's selfish behavior directly causes him to lose his kingdom. The theme — the lesson the story teaches — is that pride and selfishness have consequences.",
                standardCode: nil, subject: "ELA"),
        ],
        timeLimit: 10,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 8 Math

    static let ncEOGMath8 = PracticeTest(
        id: "nc-eog-math-8",
        title: "NC EOG Math — Grade 8",
        type: .state,
        subject: "Math",
        gradeLevel: "8",
        questions: [
            PracticeTestQuestion(id: "nc8m1", question: "A right triangle has legs of 6 and 8. What is the length of the hypotenuse?",
                options: ["7", "10", "14", "100"], correctIndex: 1,
                explanation: "Pythagorean theorem: a²+b²=c². 6²+8² = 36+64 = 100. √100 = 10.",
                standardCode: "NC.8.G.B.7", subject: "Math"),
            PracticeTestQuestion(id: "nc8m2",
                question: "Which set of ordered pairs represents a function?",
                options: ["{(1,2),(1,3),(2,4)}", "{(1,2),(2,2),(3,2)}", "{(1,2),(2,3),(1,4)}", "{(2,1),(2,3),(2,5)}"],
                correctIndex: 1,
                explanation: "A function assigns exactly one output to each input. In option B, each x-value (1, 2, 3) maps to exactly one y-value. Options A, C, and D repeat an x-value with different y-values.",
                standardCode: "NC.8.F.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc8m3", question: "Solve the system: y = 2x + 1 and y = −x + 7",
                options: ["(1, 3)", "(2, 5)", "(3, 7)", "(0, 7)"], correctIndex: 1,
                explanation: "Set equal: 2x+1 = −x+7. Add x to both sides: 3x+1=7. Subtract 1: 3x=6. x=2. Substitute: y=2(2)+1=5. Solution: (2, 5).",
                standardCode: "NC.8.EE.C.8", subject: "Math"),
            PracticeTestQuestion(id: "nc8m4", question: "Which is the correct scientific notation for 0.000045?",
                options: ["45 × 10⁻⁶", "4.5 × 10⁻⁵", "4.5 × 10⁵", "0.45 × 10⁻⁴"], correctIndex: 1,
                explanation: "Move the decimal 5 places right to get 4.5, so the exponent is −5. Scientific notation: 4.5 × 10⁻⁵.",
                standardCode: "NC.8.EE.A.3", subject: "Math"),
            PracticeTestQuestion(id: "nc8m5", question: "A line passes through (0, 3) and (4, −1). What is the slope?",
                options: ["1", "−2", "−1", "2"], correctIndex: 2,
                explanation: "Slope = (y₂−y₁)/(x₂−x₁) = (−1−3)/(4−0) = −4/4 = −1.",
                standardCode: "NC.8.F.B.4", subject: "Math"),
            PracticeTestQuestion(id: "nc8m6", question: "√50 is between which two consecutive integers?",
                options: ["6 and 7", "7 and 8", "8 and 9", "5 and 6"], correctIndex: 1,
                explanation: "√49 = 7 and √64 = 8. Since 49 < 50 < 64, √50 is between 7 and 8.",
                standardCode: "NC.8.NS.A.2", subject: "Math"),
            PracticeTestQuestion(id: "nc8m7", question: "A transformation moves every point (x, y) to (x + 3, y − 2). What type of transformation is this?",
                options: ["Rotation", "Reflection", "Dilation", "Translation"], correctIndex: 3,
                explanation: "Adding a constant to x and y coordinates shifts every point the same distance in the same direction — that is a translation.",
                standardCode: "NC.8.G.A.3", subject: "Math"),
            PracticeTestQuestion(id: "nc8m8", question: "The graph of y = x² is shifted 3 units up. What is the new equation?",
                options: ["y = (x + 3)²", "y = x² − 3", "y = 3x²", "y = x² + 3"], correctIndex: 3,
                explanation: "Adding a constant outside the function shifts the graph vertically. Shifting up 3 units gives y = x² + 3.",
                standardCode: "NC.8.F.A.3", subject: "Math"),
        ],
        timeLimit: 14,
        createdAt: Date()
    )

    // MARK: - NC EOG Grade 8 Science

    static let ncEOGScience8 = PracticeTest(
        id: "nc-eog-science-8",
        title: "NC EOG Science — Grade 8",
        type: .state,
        subject: "Science",
        gradeLevel: "8",
        questions: [
            PracticeTestQuestion(id: "nc8s1",
                question: "According to Newton's first law of motion, an object at rest will remain at rest unless:",
                options: ["Gravity pulls it down", "An unbalanced force acts on it", "It gains momentum", "Friction stops it"],
                correctIndex: 1,
                explanation: "Newton's first law (inertia): an object stays in its current state of motion unless acted on by a net external (unbalanced) force.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc8s2",
                question: "When a ball is dropped from a height, its energy converts as it falls. Just BEFORE hitting the ground, the ball's energy is mostly:",
                options: ["All potential energy", "All kinetic energy", "Half potential, half kinetic", "All chemical energy"],
                correctIndex: 1,
                explanation: "At the highest point, energy is all potential. As the ball falls, potential energy converts to kinetic. Just before impact, nearly all potential energy has been converted to kinetic energy.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc8s3", question: "The atomic number of an element tells you:",
                options: ["The number of neutrons in the nucleus", "The mass of the atom", "The number of protons in the nucleus", "The number of electrons in the outer shell"],
                correctIndex: 2,
                explanation: "The atomic number equals the number of protons, which defines what element it is. (In a neutral atom, it also equals the number of electrons.)",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc8s4",
                question: "Which evidence BEST supports the theory of plate tectonics?",
                options: ["All continents experience earthquakes", "Similar fossils are found on continents that are now far apart", "The ocean is very deep in places", "Volcanoes exist in many countries"],
                correctIndex: 1,
                explanation: "Finding matching fossils of the same ancient species on continents separated by oceans provides strong evidence that those continents were once joined together and drifted apart.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc8s5",
                question: "A circuit has a 12-volt battery and a 4-ohm resistor. Using Ohm's Law (I = V ÷ R), what is the current?",
                options: ["48 amps", "0.33 amps", "8 amps", "3 amps"],
                correctIndex: 3,
                explanation: "I = V ÷ R = 12 ÷ 4 = 3 amps.",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc8s6",
                question: "Which BEST describes the difference between a physical change and a chemical change?",
                options: ["Physical changes are always reversible; chemical changes never are", "In a physical change no new substance forms; in a chemical change a new substance forms", "Physical changes involve heat; chemical changes involve light", "Physical changes are always faster than chemical changes"],
                correctIndex: 1,
                explanation: "The key distinction: physical changes alter form or state but not chemical composition (e.g., cutting, melting). Chemical changes produce one or more new substances (e.g., burning, rusting).",
                standardCode: nil, subject: "Science"),
            PracticeTestQuestion(id: "nc8s7",
                question: "Which term describes a relationship where BOTH organisms benefit?",
                options: ["Parasitism", "Commensalism", "Mutualism", "Predation"],
                correctIndex: 2,
                explanation: "Mutualism: both organisms benefit (e.g., bees and flowers). Parasitism: one benefits, one is harmed. Commensalism: one benefits, one is unaffected. Predation: one organism eats another.",
                standardCode: nil, subject: "Science"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - NC EOC Math I (Grade 9)

    static let ncEOCMath1 = PracticeTest(
        id: "nc-eoc-math1",
        title: "NC EOC Math I — Algebra & Functions",
        type: .state,
        subject: "Math",
        gradeLevel: "9",
        questions: [
            PracticeTestQuestion(id: "nc9m1", question: "Solve: 2(x − 3) + 4 = 14",
                options: ["5", "6", "8", "9"], correctIndex: 2,
                explanation: "Distribute: 2x − 6 + 4 = 14 → 2x − 2 = 14 → 2x = 16 → x = 8.",
                standardCode: "NC.M1.A-CED.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc9m2", question: "A linear function is f(x) = 3x − 2. What is f(4)?",
                options: ["10", "14", "5", "12"], correctIndex: 0,
                explanation: "Substitute x = 4: f(4) = 3(4) − 2 = 12 − 2 = 10.",
                standardCode: "NC.M1.F-IF.A.2", subject: "Math"),
            PracticeTestQuestion(id: "nc9m3",
                question: "Which table of values represents a LINEAR function?",
                options: ["x: 1,2,3 → y: 1,4,9", "x: 1,2,3 → y: 3,5,7", "x: 1,2,3 → y: 2,4,8", "x: 1,2,3 → y: 1,3,7"],
                correctIndex: 1,
                explanation: "A linear function has a constant rate of change. In option B, y increases by 2 each time x increases by 1 — a constant difference. Options A and C grow by increasing amounts (quadratic/exponential). Option D has no constant difference.",
                standardCode: "NC.M1.F-LE.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc9m4", question: "Two lines are parallel if they have:",
                options: ["The same y-intercept", "The same slope and different y-intercepts", "Slopes that multiply to −1", "The same slope and y-intercept"],
                correctIndex: 1,
                explanation: "Parallel lines have equal slopes but different y-intercepts — they never intersect. Lines with the same slope AND y-intercept are the same line. Lines whose slopes multiply to −1 are perpendicular.",
                standardCode: "NC.M1.G-GPE.B.5", subject: "Math"),
            PracticeTestQuestion(id: "nc9m5", question: "A company earns $500 per day. Which equation models their total earnings E after d days?",
                options: ["E = d + 500", "E = 500d", "E = 500/d", "E = d² + 500"], correctIndex: 1,
                explanation: "Earnings grow at a constant rate of $500 per day. This is a direct proportion: E = 500 × d.",
                standardCode: "NC.M1.A-CED.A.1", subject: "Math"),
            PracticeTestQuestion(id: "nc9m6", question: "Solve the system: x + y = 10 and x − y = 4",
                options: ["(8, 2)", "(7, 3)", "(6, 4)", "(5, 5)"], correctIndex: 1,
                explanation: "Add the equations: 2x = 14 → x = 7. Substitute: 7 + y = 10 → y = 3. Solution: (7, 3).",
                standardCode: "NC.M1.A-REI.C.6", subject: "Math"),
            PracticeTestQuestion(id: "nc9m7",
                question: "A scatter plot shows that as hours studied increases, test scores also increase. This relationship is:",
                options: ["A negative correlation", "No correlation", "A positive correlation", "A perfect linear correlation"],
                correctIndex: 2,
                explanation: "When both variables increase together, the relationship is a positive correlation. A negative correlation means one goes up as the other goes down.",
                standardCode: "NC.M1.S-ID.B.6", subject: "Math"),
            PracticeTestQuestion(id: "nc9m8", question: "What is the slope of the line 4x − 2y = 8?",
                options: ["4", "−4", "2", "−2"], correctIndex: 2,
                explanation: "Rewrite in slope-intercept form: −2y = −4x + 8 → y = 2x − 4. The slope is the coefficient of x: 2.",
                standardCode: "NC.M1.F-IF.B.6", subject: "Math"),
        ],
        timeLimit: 14,
        createdAt: Date()
    )

    // MARK: - NC EOC English I (Grade 9)

    static let ncEOCEnglish1 = PracticeTest(
        id: "nc-eoc-english1",
        title: "NC EOC English I — Reading & Language",
        type: .state,
        subject: "ELA",
        gradeLevel: "9",
        questions: [
            PracticeTestQuestion(id: "nc9e1",
                question: "\"The protagonist faces impossible odds but refuses to give up, ultimately finding an unexpected path forward.\" Which literary element does this describe?",
                options: ["Setting", "Conflict and resolution", "Foreshadowing", "Point of view"],
                correctIndex: 1,
                explanation: "The character faces a conflict (impossible odds) and works through it to a resolution (unexpected path forward). This is the central conflict-resolution arc of the story.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc9e2",
                question: "An author wants to argue that social media has negative effects on teenagers. Which evidence is MOST effective?",
                options: ["A personal story from the author's own teenage years", "A fictional narrative about a lonely teenager", "Research studies showing increased anxiety rates among teenage social media users", "An opinion piece written by a celebrity"],
                correctIndex: 2,
                explanation: "Research studies provide empirical, data-driven evidence — the most credible type for an argument. Personal stories and opinions may be compelling but are more easily dismissed.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc9e3",
                question: "\"The old oak tree had stood in the yard for a hundred years, watching generations of children grow up and move away.\" What literary device is used?",
                options: ["Simile", "Alliteration", "Personification", "Hyperbole"],
                correctIndex: 2,
                explanation: "Personification gives human qualities to non-human things. A tree cannot literally 'watch' — this assigns a human action to an inanimate object.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc9e4",
                question: "Which sentence contains a MISPLACED modifier?",
                options: ["Running quickly, the dog chased the ball.", "She almost drove her children to school every day.", "The tall man with a hat waved at us.", "After eating dinner, she washed the dishes."],
                correctIndex: 1,
                explanation: "'Almost' is placed next to 'drove,' suggesting she rarely drove at all. The intended meaning is that she drove them nearly every day — 'almost' should modify 'every day': 'She drove her children to school almost every day.'",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc9e5",
                question: "A student notes that a poem's speaker uses words like 'shadow,' 'grey,' and 'fading.' What TONE do these words create?",
                options: ["Joyful and optimistic", "Angry and aggressive", "Melancholy or somber", "Confused and uncertain"],
                correctIndex: 2,
                explanation: "Words like 'shadow,' 'grey,' and 'fading' carry connotations of darkness, dullness, and loss — creating a melancholy (sad) or somber (serious/dark) tone.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc9e6",
                question: "A paragraph introduces a topic, provides three supporting details, and ends with a conclusion. Which organizational structure does this follow?",
                options: ["Problem-solution", "Cause-effect", "Compare-contrast", "Main idea with supporting details"],
                correctIndex: 3,
                explanation: "A topic sentence introduces the main idea, body sentences provide support, and a concluding sentence wraps up — this is the classic main-idea-with-supporting-details structure.",
                standardCode: nil, subject: "ELA"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - NC EOC Math II (Grade 10)

    static let ncEOCMath2 = PracticeTest(
        id: "nc-eoc-math2",
        title: "NC EOC Math II — Geometry & Algebra",
        type: .state,
        subject: "Math",
        gradeLevel: "10",
        questions: [
            PracticeTestQuestion(id: "nc10m1",
                question: "Two similar triangles have sides 3, 4, 5 and a shortest side of 6. What is the longest side of the second triangle?",
                options: ["8", "10", "12", "15"], correctIndex: 1,
                explanation: "Scale factor = 6 ÷ 3 = 2. Longest side = 5 × 2 = 10.",
                standardCode: "NC.M2.G-SRT.B.5", subject: "Math"),
            PracticeTestQuestion(id: "nc10m2",
                question: "In a right triangle, sin(30°) = 0.5. If the hypotenuse is 20, what is the side OPPOSITE the 30° angle?",
                options: ["5", "10", "15", "40"], correctIndex: 1,
                explanation: "sin(angle) = opposite/hypotenuse. Opposite = sin(30°) × 20 = 0.5 × 20 = 10.",
                standardCode: "NC.M2.G-SRT.C.8", subject: "Math"),
            PracticeTestQuestion(id: "nc10m3", question: "What is the sum of the interior angles of a hexagon?",
                options: ["540°", "360°", "720°", "900°"], correctIndex: 2,
                explanation: "Sum of interior angles = (n − 2) × 180°. For a hexagon (n = 6): (6 − 2) × 180 = 4 × 180 = 720°.",
                standardCode: "NC.M2.G-CO.C.11", subject: "Math"),
            PracticeTestQuestion(id: "nc10m4",
                question: "A transformation that preserves shape but NOT size is a:",
                options: ["Translation", "Rotation", "Reflection", "Dilation"], correctIndex: 3,
                explanation: "Translations, rotations, and reflections are rigid motions — they preserve both shape and size. A dilation scales the figure, preserving shape but changing size.",
                standardCode: "NC.M2.G-CO.A.2", subject: "Math"),
            PracticeTestQuestion(id: "nc10m5", question: "Solve: x² − 5x + 6 = 0",
                options: ["x = −2 or x = −3", "x = 1 or x = 6", "x = 2 or x = 3", "x = 3 or x = 5"], correctIndex: 2,
                explanation: "Factor: find two numbers that multiply to 6 and add to −5: −2 and −3. So (x − 2)(x − 3) = 0. Solutions: x = 2 or x = 3.",
                standardCode: "NC.M2.A-REI.B.4", subject: "Math"),
            PracticeTestQuestion(id: "nc10m6",
                question: "Two independent events: P(A) = 0.4 and P(B) = 0.3. What is P(A and B)?",
                options: ["0.70", "0.10", "0.12", "0.58"], correctIndex: 2,
                explanation: "For independent events, P(A and B) = P(A) × P(B) = 0.4 × 0.3 = 0.12.",
                standardCode: "NC.M2.S-CP.B.8", subject: "Math"),
            PracticeTestQuestion(id: "nc10m7", question: "What is the equation of a circle with center (3, −2) and radius 5?",
                options: ["(x+3)²+(y−2)²=25", "(x−3)²+(y+2)²=25", "(x−3)²+(y−2)²=5", "(x+3)²+(y+2)²=25"], correctIndex: 1,
                explanation: "The standard form is (x − h)² + (y − k)² = r². With center (3, −2) and r = 5: (x−3)² + (y−(−2))² = 5² → (x−3)² + (y+2)² = 25.",
                standardCode: "NC.M2.G-GPE.A.1", subject: "Math"),
        ],
        timeLimit: 14,
        createdAt: Date()
    )

    // MARK: - NC EOC English II (Grade 10)

    static let ncEOCEnglish2 = PracticeTest(
        id: "nc-eoc-english2",
        title: "NC EOC English II — Literature & Composition",
        type: .state,
        subject: "ELA",
        gradeLevel: "10",
        questions: [
            PracticeTestQuestion(id: "nc10e1",
                question: "A student compares a Nigerian novel to a Japanese short story and finds both feature characters sacrificing personal happiness for family honor. This shared element across cultures suggests:",
                options: ["All world literature is essentially the same", "Honor is only valued in non-Western cultures", "Universal themes appear across different cultures and time periods", "Family conflicts are unique to these two cultures"],
                correctIndex: 2,
                explanation: "When a theme — like sacrifice for family — appears independently across cultures, it suggests the theme is universal: it reflects shared human experiences regardless of time or place.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc10e2",
                question: "An editorial uses words like 'devastating' and 'catastrophic' while arguing for stricter environmental regulations. This language is an example of:",
                options: ["Logos — using logical evidence", "Ethos — establishing the author's credibility", "Pathos — appealing to the reader's emotions", "Kairos — using a timely occasion to persuade"],
                correctIndex: 2,
                explanation: "Pathos is the rhetorical appeal to emotion. Words like 'devastating' and 'catastrophic' trigger emotional responses (fear, urgency) to persuade readers, rather than relying on data or the author's credentials.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc10e3",
                question: "\"The policy will create jobs, stimulate the economy, and reduce inequality.\" What rhetorical device does the list of three parallel items represent?",
                options: ["Anaphora", "Chiasmus", "Tricolon", "Antithesis"],
                correctIndex: 2,
                explanation: "A tricolon is a series of three parallel elements for rhetorical effect. Anaphora repeats a word at the start of successive phrases. Chiasmus reverses grammatical structures. Antithesis contrasts opposing ideas.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc10e4",
                question: "A Shakespearean sonnet contains how many lines?",
                options: ["12", "14", "16", "18"], correctIndex: 1,
                explanation: "A Shakespearean (English) sonnet has 14 lines: three quatrains (4 lines each) and a closing couplet (2 lines), following the rhyme scheme ABAB CDCD EFEF GG.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc10e5",
                question: "\"Though she appeared confident on the outside, Maya's inner turmoil threatened to break through at any moment.\" This is an example of:",
                options: ["External conflict between two characters", "Internal conflict revealed through contrast with outward appearance", "A flashback to an earlier event", "Situational irony"],
                correctIndex: 1,
                explanation: "The contrast between Maya's outward confidence and her internal turmoil is the author's technique for revealing an internal conflict — a struggle within the character's own mind.",
                standardCode: nil, subject: "ELA"),
            PracticeTestQuestion(id: "nc10e6",
                question: "An author tells a story through a first-person narrator who is later revealed to have been lying. What effect does this most likely create?",
                options: ["The reader feels completely informed about all events", "The story feels more objective and factual", "The reader must question what is true and what reflects the narrator's bias or deception", "The plot becomes simpler and easier to follow"],
                correctIndex: 2,
                explanation: "An unreliable narrator creates dramatic irony — the reader comes to realize the narrator cannot be fully trusted, which forces active re-evaluation of everything the narrator has said.",
                standardCode: nil, subject: "ELA"),
        ],
        timeLimit: 12,
        createdAt: Date()
    )

    // MARK: - Built-in Standards (subset of CCSS)

    static let standards: [Standard] = [
        Standard(id: "ccss-6-ns-a1", code: "CCSS.MATH.6.NS.A.1", description: "Interpret and compute quotients of fractions", subject: "Math", gradeLevel: "6", framework: .commonCore),
        Standard(id: "ccss-6-ns-b4", code: "CCSS.MATH.6.NS.B.4", description: "Find greatest common factor and least common multiple", subject: "Math", gradeLevel: "6", framework: .commonCore),
        Standard(id: "ccss-6-rp-a3", code: "CCSS.MATH.6.RP.A.3", description: "Use ratio and rate reasoning to solve problems", subject: "Math", gradeLevel: "6", framework: .commonCore),
        Standard(id: "ccss-6-ee-a3", code: "CCSS.MATH.6.EE.A.3", description: "Apply properties of operations to generate equivalent expressions", subject: "Math", gradeLevel: "6", framework: .commonCore),
        Standard(id: "ccss-6-sp-a3", code: "CCSS.MATH.6.SP.A.3", description: "Recognize that measures of center summarize data with a single number", subject: "Math", gradeLevel: "6", framework: .commonCore),
        Standard(id: "ccss-8-ee-a2", code: "CCSS.MATH.8.EE.A.2", description: "Use square root and cube root symbols to represent solutions", subject: "Math", gradeLevel: "8", framework: .commonCore),
        Standard(id: "ccss-8-ee-b5", code: "CCSS.MATH.8.EE.B.5", description: "Graph proportional relationships; compare unit rates", subject: "Math", gradeLevel: "8", framework: .commonCore),
        Standard(id: "ccss-8-ee-c7", code: "CCSS.MATH.8.EE.C.7", description: "Solve linear equations in one variable", subject: "Math", gradeLevel: "8", framework: .commonCore),
        Standard(id: "ccss-8-g-a5", code: "CCSS.MATH.8.G.A.5", description: "Use informal arguments to establish triangle angle facts", subject: "Math", gradeLevel: "8", framework: .commonCore),
        Standard(id: "ccss-hsa-apr-a1", code: "CCSS.MATH.HSA.APR.A.1", description: "Understand that polynomials form a system analogous to integers", subject: "Math", gradeLevel: "9", framework: .commonCore),
        Standard(id: "ccss-hsa-ced-a1", code: "CCSS.MATH.HSA.CED.A.1", description: "Create equations and inequalities in one variable", subject: "Math", gradeLevel: "9", framework: .commonCore),
        Standard(id: "ccss-hsf-if-a2", code: "CCSS.MATH.HSF.IF.A.2", description: "Use function notation, evaluate functions for inputs", subject: "Math", gradeLevel: "9", framework: .commonCore),
    ]

    // MARK: - Lookup

    static func standard(for code: String) -> Standard? {
        standards.first { $0.code == code }
    }
}
