const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const Anthropic = require("@anthropic-ai/sdk").default;

initializeApp();

exports.askCompanion = onCall(
  { secrets: ["ANTHROPIC_API_KEY"], region: "us-central1" },
  async (request) => {
    // Require authentication
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const { message, studentId, conversationId } = request.data;

    if (!message || !studentId || !conversationId) {
      throw new HttpsError("invalid-argument", "Missing required fields.");
    }

    const db = getFirestore();

    // Fetch student context in parallel
    const [profileSnap, pathsSnap] = await Promise.all([
      db.collection("learningProfiles").doc(studentId).get(),
      db.collection("learningPaths")
        .where("studentId", "==", studentId)
        .where("isActive", "==", true)
        .limit(1)
        .get(),
    ]);

    const profile = profileSnap.data() || {};
    const activePath = pathsSnap.docs[0]?.data();

    // Build context-aware system prompt
    let systemPrompt =
      "You are EduAssist AI, a helpful and encouraging educational companion for K-12 students. " +
      "Be supportive, concise, and age-appropriate. Help students understand concepts, " +
      "work through problems step by step, and stay motivated. " +
      "If asked about something inappropriate or off-topic, gently redirect to learning.";

    if (profile.learningStyle) {
      systemPrompt += ` This student's dominant learning style is ${profile.learningStyle} — tailor your explanations accordingly.`;
    }
    if (profile.gradeLevel) {
      systemPrompt += ` They are in grade ${profile.gradeLevel}.`;
    }
    if (activePath?.title) {
      systemPrompt += ` They are currently working on a learning path called "${activePath.title}".`;
    }
    if (profile.interests && profile.interests.length > 0) {
      systemPrompt += ` Their interests include: ${profile.interests.join(", ")}.`;
    }

    // Load recent conversation history (last 10 messages for context)
    const historySnap = await db
      .collection("conversations")
      .doc(conversationId)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(10)
      .get();

    const history = historySnap.docs
      .reverse()
      .map((doc) => {
        const d = doc.data();
        return { role: d.role, content: d.text };
      });

    // Call Claude
    const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-6",
      max_tokens: 1024,
      system: systemPrompt,
      messages: [...history, { role: "user", content: message }],
    });

    const replyText = response.content[0].text;

    // Persist both messages to Firestore
    const messagesRef = db
      .collection("conversations")
      .doc(conversationId)
      .collection("messages");

    const batch = db.batch();
    batch.set(messagesRef.doc(), {
      role: "user",
      text: message,
      createdAt: FieldValue.serverTimestamp(),
    });
    batch.set(messagesRef.doc(), {
      role: "assistant",
      text: replyText,
      createdAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return { reply: replyText };
  }
);

// MARK: - Generate AI Recommendations
exports.generateRecommendations = onCall(
  { secrets: ["ANTHROPIC_API_KEY"], region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const { studentId } = request.data;
    if (!studentId) {
      throw new HttpsError("invalid-argument", "Missing studentId.");
    }

    const db = getFirestore();

    // Fetch student context
    const [profileSnap, pathsSnap, progressSnap] = await Promise.all([
      db.collection("learningProfiles").doc(studentId).get(),
      db.collection("learningPaths").where("studentId", "==", studentId).get(),
      db.collection("studentProgress").where("studentId", "==", studentId).get(),
    ]);

    const profile = profileSnap.data() || {};
    const paths = pathsSnap.docs.map((d) => d.data());
    const progressList = progressSnap.docs.map((d) => d.data());

    const completedIds = new Set(
      progressList.filter((p) => p.status === "completed").map((p) => p.contentItemId)
    );
    const totalItems = paths.flatMap((p) => p.items || []).length;
    const completedCount = progressList.filter((p) => p.status === "completed").length;

    const prompt = `You are an educational AI advisor. Based on this student's profile, generate exactly 3 specific learning recommendations.

Student Profile:
- Learning Style: ${profile.learningStyle || "unknown"}
- Grade Level: ${profile.gradeLevel || "unknown"}
- Interests: ${(profile.interests || []).join(", ") || "none listed"}
- Completed ${completedCount} of ${totalItems} assigned lessons
- Active learning paths: ${paths.map((p) => p.title).join(", ") || "none"}

Return a JSON array of exactly 3 objects, each with:
- "type": one of "learningPath", "contentItem", or "quiz"
- "title": specific, actionable title (max 60 chars)
- "rationale": 1-2 sentences explaining why this helps this specific student

Return ONLY the JSON array, no other text.`;

    const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
    const response = await anthropic.messages.create({
      model: "claude-sonnet-4-6",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
    });

    let recommendations = [];
    try {
      recommendations = JSON.parse(response.content[0].text);
    } catch {
      throw new HttpsError("internal", "Failed to parse AI recommendations.");
    }

    // Save each recommendation as pending
    const batch = db.batch();
    for (const rec of recommendations) {
      const docRef = db.collection("recommendations").doc();
      batch.set(docRef, {
        id: docRef.id,
        studentId,
        type: rec.type,
        title: rec.title,
        rationale: rec.rationale,
        suggestedBy: "ai",
        status: "pending",
        reviewedBy: null,
        reviewedAt: null,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return { count: recommendations.length };
  }
);

// MARK: - Curate Content (Khan Academy)
exports.curateContent = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in.");
    }

    const { subject = "Math", gradeLevel = "6" } = request.data;

    const slugMap = {
      math: "math", mathematics: "math", algebra: "algebra",
      geometry: "geometry", calculus: "calculus",
      science: "science", biology: "biology",
      chemistry: "chemistry", physics: "physics",
      computing: "computing", "computer science": "computing", programming: "computing",
      history: "us-history", "world history": "world-history",
      english: "grammar", grammar: "grammar", writing: "grammar",
      economics: "economics-finance-domain", finance: "economics-finance-domain",
      art: "art-history", music: "music",
    };

    const key = subject.toLowerCase().trim();
    const slug = slugMap[key] || slugMap[key.split(" ")[0]] || "math";

    try {
      const [videoResult, articleResult] = await Promise.allSettled([
        fetch(`https://www.khanacademy.org/api/v1/topic/${slug}/videos`),
        fetch(`https://www.khanacademy.org/api/v1/topic/${slug}/articles`),
      ]);

      let items = [];

      if (videoResult.status === "fulfilled" && videoResult.value.ok) {
        const videos = await videoResult.value.json();
        const mapped = (Array.isArray(videos) ? videos : [])
          .slice(0, 10)
          .map((v) => ({
            externalId: v.id || v.readable_id || String(Math.random()),
            title: v.title || "Untitled",
            description: v.description || v.translated_description || "",
            contentType: "video",
            url: `https://www.khanacademy.org${v.url || v.ka_url || ""}`,
            source: "khanacademy",
            subject,
            estimatedMinutes: Math.max(1, Math.round((v.duration || 300) / 60)),
          }))
          .filter((v) => v.url && v.url !== "https://www.khanacademy.org");
        items = [...items, ...mapped];
      }

      if (articleResult.status === "fulfilled" && articleResult.value.ok) {
        const articles = await articleResult.value.json();
        const mapped = (Array.isArray(articles) ? articles : [])
          .slice(0, 5)
          .map((a) => ({
            externalId: a.id || a.readable_id || String(Math.random()),
            title: a.title || "Untitled",
            description: a.description || a.translated_description || "",
            contentType: "article",
            url: `https://www.khanacademy.org${a.url || a.ka_url || ""}`,
            source: "khanacademy",
            subject,
            estimatedMinutes: 8,
          }))
          .filter((a) => a.url && a.url !== "https://www.khanacademy.org");
        items = [...items, ...mapped];
      }

      if (items.length === 0) {
        items = getFallbackItems(subject);
      }

      return { items };
    } catch (error) {
      console.error("curateContent error:", error.message);
      return { items: getFallbackItems(subject) };
    }
  }
);

function getFallbackItems(subject) {
  const key = (subject || "math").toLowerCase();
  const catalog = {
    math: [
      { externalId: "ka-var-1", title: "What is a Variable?", description: "Introduction to variables in algebra", contentType: "video", url: "https://www.khanacademy.org/math/algebra/x2f8bb11595b61c86:foundation-algebra/x2f8bb11595b61c86:intro-variables/v/what-is-a-variable", source: "khanacademy", subject: "Math", estimatedMinutes: 5 },
      { externalId: "ka-frac-1", title: "Concept of a Fraction", description: "Understanding fractions as parts of a whole", contentType: "video", url: "https://www.khanacademy.org/math/arithmetic/fraction-arithmetic/arith-review-fractions/v/concept-of-a-fraction", source: "khanacademy", subject: "Math", estimatedMinutes: 6 },
      { externalId: "ka-prob-1", title: "Basic Probability", description: "Introduction to probability and simple events", contentType: "video", url: "https://www.khanacademy.org/math/statistics-probability/basic-theoretical-probability/basic-probability/v/basic-probability", source: "khanacademy", subject: "Math", estimatedMinutes: 10 },
      { externalId: "ka-angle-1", title: "Angle Basics", description: "Learn about types of angles and how to measure them", contentType: "video", url: "https://www.khanacademy.org/math/basic-geo/basic-geo-angle/basic-geo-angles/v/angle-basics", source: "khanacademy", subject: "Math", estimatedMinutes: 7 },
      { externalId: "ka-dec-1", title: "Decimals and Place Value", description: "Understanding the decimal number system", contentType: "video", url: "https://www.khanacademy.org/math/arithmetic/arith-decimals/intro-to-decimals/v/decimal-place-value", source: "khanacademy", subject: "Math", estimatedMinutes: 8 },
    ],
    science: [
      { externalId: "ka-cell-1", title: "Introduction to Cells", description: "Overview of cell structure and function", contentType: "video", url: "https://www.khanacademy.org/science/biology/structure-of-a-cell/intro-to-cells/v/intro-to-cells", source: "khanacademy", subject: "Science", estimatedMinutes: 10 },
      { externalId: "ka-newton-1", title: "Newton's First Law of Motion", description: "Understanding inertia and the first law", contentType: "video", url: "https://www.khanacademy.org/science/physics/forces-newtons-laws/newtons-laws-of-motion/v/newton-s-first-law-of-motion", source: "khanacademy", subject: "Science", estimatedMinutes: 9 },
      { externalId: "ka-eco-1", title: "Introduction to Ecosystems", description: "How living things interact with their environment", contentType: "video", url: "https://www.khanacademy.org/science/biology/ecology/intro-to-ecosystems/v/ecosystems", source: "khanacademy", subject: "Science", estimatedMinutes: 11 },
      { externalId: "ka-atom-1", title: "Introduction to Atoms", description: "The building blocks of matter", contentType: "video", url: "https://www.khanacademy.org/science/chemistry/atomic-structure-and-properties/introduction-to-the-atom/v/introduction-to-the-atom", source: "khanacademy", subject: "Science", estimatedMinutes: 12 },
    ],
    computing: [
      { externalId: "ka-algo-1", title: "What is an Algorithm?", description: "Understanding algorithms as step-by-step instructions", contentType: "article", url: "https://www.khanacademy.org/computing/computer-science/algorithms/intro-to-algorithms/a/what-is-an-algorithm", source: "khanacademy", subject: "Computing", estimatedMinutes: 5 },
      { externalId: "ka-bin-1", title: "Binary Numbers", description: "How computers represent numbers in binary", contentType: "video", url: "https://www.khanacademy.org/computing/computers-and-internet/x261d2625:digital-information/x261d2625:binary-numbers/v/binary-numbers", source: "khanacademy", subject: "Computing", estimatedMinutes: 8 },
      { externalId: "ka-html-1", title: "Intro to HTML", description: "Getting started with web development", contentType: "article", url: "https://www.khanacademy.org/computing/computer-programming/html-css/intro-to-html/pt/html-basics", source: "khanacademy", subject: "Computing", estimatedMinutes: 10 },
    ],
    history: [
      { externalId: "ka-era-1", title: "The Age of Exploration", description: "European exploration and contact with the Americas", contentType: "video", url: "https://www.khanacademy.org/humanities/us-history/precontact-and-early-colonial-era/before-contact/v/americas-before-contact", source: "khanacademy", subject: "History", estimatedMinutes: 11 },
      { externalId: "ka-rev-1", title: "The American Revolution", description: "Causes and key events of the American Revolution", contentType: "video", url: "https://www.khanacademy.org/humanities/us-history/road-to-revolution/american-revolution/v/american-revolution", source: "khanacademy", subject: "History", estimatedMinutes: 14 },
    ],
    economics: [
      { externalId: "ka-sup-1", title: "Supply and Demand", description: "Core concepts of markets and pricing", contentType: "video", url: "https://www.khanacademy.org/economics-finance-domain/microeconomics/supply-demand-equilibrium/supply-and-demand/v/law-of-demand", source: "khanacademy", subject: "Economics", estimatedMinutes: 8 },
      { externalId: "ka-gdp-1", title: "What is GDP?", description: "How we measure the size of an economy", contentType: "video", url: "https://www.khanacademy.org/economics-finance-domain/macroeconomics/gdp-topic/gdp/v/introduction-to-gdp", source: "khanacademy", subject: "Economics", estimatedMinutes: 9 },
    ],
    grammar: [
      { externalId: "ka-gram-1", title: "What is a Noun?", description: "Introduction to nouns in English grammar", contentType: "video", url: "https://www.khanacademy.org/humanities/grammar/partsofspeech/theNoun/v/introduction-to-nouns-the-parts-of-speech-grammar", source: "khanacademy", subject: "English", estimatedMinutes: 5 },
      { externalId: "ka-gram-2", title: "Subject-Verb Agreement", description: "Making subjects and verbs agree in sentences", contentType: "video", url: "https://www.khanacademy.org/humanities/grammar/partsofspeech/the-verb/v/subject-verb-agreement", source: "khanacademy", subject: "English", estimatedMinutes: 7 },
    ],
    art: [
      { externalId: "ka-art-1", title: "A Beginner's Guide to Art History", description: "Introduction to studying art history", contentType: "article", url: "https://www.khanacademy.org/humanities/art-history/art-history-beginners-guide/a/a-beginners-guide-to-art-history", source: "khanacademy", subject: "Art", estimatedMinutes: 8 },
    ],
  };

  for (const [k, items] of Object.entries(catalog)) {
    if (key.includes(k) || k.includes(key)) return items;
  }
  return catalog.math;
}

// MARK: - Push Notifications

// Fires when a new recommendation is created — notifies linked teachers and parents.
exports.onRecommendationCreated = onDocumentCreated(
  { document: "recommendations/{recId}", region: "us-central1" },
  async (event) => {
    const rec = event.data.data();
    if (!rec || !rec.studentId) return;

    const db = getFirestore();
    const messaging = getMessaging();

    // Fetch linked adults for this student
    const linksSnap = await db.collection("studentAdultLinks")
      .where("studentId", "==", rec.studentId)
      .where("confirmed", "==", true)
      .get();

    const adultIds = linksSnap.docs.map((d) => d.data().adultId).filter(Boolean);
    if (adultIds.length === 0) return;

    // Collect FCM tokens
    const tokens = [];
    for (const adultId of adultIds) {
      const userSnap = await db.collection("users").doc(adultId).get();
      const token = userSnap.data()?.fcmToken;
      if (token) tokens.push(token);
    }
    if (tokens.length === 0) return;

    const title = "New AI Recommendation";
    const body = `Review suggested content for your student: "${rec.title}"`;

    await messaging.sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { type: "recommendation", recId: event.params.recId, studentId: rec.studentId },
    });
  }
);

// Fires when a new message is sent — notifies the other participant.
exports.onMessageCreated = onDocumentCreated(
  { document: "messageThreads/{threadId}/messages/{msgId}", region: "us-central1" },
  async (event) => {
    const msg = event.data.data();
    if (!msg || !msg.threadId || !msg.senderId) return;

    const db = getFirestore();
    const messaging = getMessaging();

    const threadSnap = await db.collection("messageThreads").doc(msg.threadId).get();
    const participants = threadSnap.data()?.participants ?? [];
    const recipients = participants.filter((id) => id !== msg.senderId);

    const tokens = [];
    for (const uid of recipients) {
      const userSnap = await db.collection("users").doc(uid).get();
      const token = userSnap.data()?.fcmToken;
      if (token) tokens.push(token);
    }
    if (tokens.length === 0) return;

    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: `New message from ${msg.senderName}`,
        body: msg.body.length > 80 ? msg.body.slice(0, 77) + "…" : msg.body,
      },
      data: { type: "message", threadId: msg.threadId },
    });
  }
);
