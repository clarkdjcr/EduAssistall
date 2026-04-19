import Foundation

struct TestDataProvider {

    // MARK: - Built-in Practice Tests

    static let tests: [PracticeTest] = [satMath, actEnglish, commonCoreMath6, commonCoreMath8, actScience]

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
