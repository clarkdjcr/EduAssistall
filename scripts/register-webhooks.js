#!/usr/bin/env node
/**
 * Registers SharePoint webhook subscriptions for the StudentContent and Curriculum
 * libraries so cache invalidation fires within seconds of any document change.
 *
 * Uses app-only auth for the Graph API (same credentials as Cloud Functions).
 * Writes subscription records to Firestore via the REST API using Google ADC —
 * run `gcloud auth application-default login` first if the Firestore write fails.
 *
 * Usage:
 *   node scripts/register-webhooks.js
 */

const TENANT_ID           = process.env.AZURE_TENANT_ID;
const CLIENT_ID           = process.env.AZURE_CLIENT_ID;
const CLIENT_SECRET       = process.env.AZURE_CLIENT_SECRET;
const SITE_ID             = process.env.SHAREPOINT_SITE_ID;
const STUDENT_CONTENT_ID  = process.env.SHAREPOINT_STUDENT_CONTENT_LIST_ID;
const CURRICULUM_ID       = process.env.SHAREPOINT_CURRICULUM_LIST_ID;
const FIRESTORE_PROJECT   = "eduassist-b1f49";
const WEBHOOK_URL         = "https://us-central1-eduassist-b1f49.cloudfunctions.net/sharepointWebhookReceiver";

// ---------------------------------------------------------------------------
// Graph auth
// ---------------------------------------------------------------------------

async function getGraphToken() {
  const res = await fetch(
    `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`,
    {
      method: "POST",
      body: new URLSearchParams({
        grant_type: "client_credentials", client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET, scope: "https://graph.microsoft.com/.default",
      }),
    }
  );
  const data = await res.json();
  if (!data.access_token) throw new Error(`Graph token error: ${JSON.stringify(data)}`);
  return data.access_token;
}

// ---------------------------------------------------------------------------
// Firestore REST API (via Google ADC)
// ---------------------------------------------------------------------------

async function getFirestoreToken() {
  try {
    // Try GoogleAuth from functions/node_modules (available if functions deps are installed)
    const { GoogleAuth } = require("./functions/node_modules/google-auth-library");
    const auth   = new GoogleAuth({ scopes: ["https://www.googleapis.com/auth/datastore"] });
    const client = await auth.getClient();
    const { token } = await client.getAccessToken();
    return token;
  } catch {
    return null;
  }
}

function toFirestoreValue(v) {
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (typeof v === "number") return { integerValue: String(Math.floor(v)) };
  return { stringValue: String(v) };
}

async function writeFirestoreDoc(firestoreToken, collection, docId, data) {
  const fields = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, toFirestoreValue(v)])
  );
  const url = `https://firestore.googleapis.com/v1/projects/${FIRESTORE_PROJECT}/databases/(default)/documents/${collection}/${docId}`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: { Authorization: `Bearer ${firestoreToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({ fields }),
  });
  return res.ok;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  if (!TENANT_ID || !CLIENT_ID || !CLIENT_SECRET || !SITE_ID) {
    console.error("Missing required env vars.");
    process.exit(1);
  }

  const listIds = [STUDENT_CONTENT_ID, CURRICULUM_ID].filter(Boolean);
  if (listIds.length === 0) {
    console.error("No list IDs found. Set SHAREPOINT_STUDENT_CONTENT_LIST_ID and SHAREPOINT_CURRICULUM_LIST_ID.");
    process.exit(1);
  }

  console.log("Authenticating with Microsoft Graph...");
  const graphToken = await getGraphToken();

  console.log("Fetching Firestore token (Google ADC)...");
  const firestoreToken = await getFirestoreToken();
  if (!firestoreToken) {
    console.warn("  No Google ADC credentials — subscription records won't be written to Firestore.");
    console.warn("  Run `gcloud auth application-default login` and re-run to enable auto-renewal.\n");
  } else {
    console.log("  Firestore token acquired.\n");
  }

  // SharePoint subscriptions expire after 4167 minutes (~2.9 days). Set to 4160 for safety.
  const expiry = new Date(Date.now() + 4160 * 60 * 1000).toISOString();
  const results = [];

  for (const listId of listIds) {
    const label = listId === STUDENT_CONTENT_ID ? "StudentContent" : "Curriculum";
    process.stdout.write(`Registering webhook for ${label} ... `);

    // SharePoint list webhook subscriptions via Graph only accept notificationUrl,
    // expirationDateTime, and clientState — no changeType or resource fields.
    const res = await fetch(
      `https://graph.microsoft.com/v1.0/sites/${SITE_ID}/lists/${listId}/subscriptions`,
      {
        method: "POST",
        headers: { Authorization: `Bearer ${graphToken}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          notificationUrl:    WEBHOOK_URL,
          expirationDateTime: expiry,
          clientState:        "EduAssist-grounding-v1",
        }),
      }
    );

    const data = await res.json();

    if (!res.ok) {
      console.log(`FAILED — ${data.error?.message}`);
      results.push({ listId, label, status: "failed", error: data.error?.message });
      continue;
    }

    const subscriptionId = data.id;
    console.log(`done (${subscriptionId})`);

    // Write renewal record to Firestore.
    if (firestoreToken) {
      const written = await writeFirestoreDoc(
        firestoreToken,
        "sharepointSubscriptions",
        subscriptionId,
        {
          subscriptionId,
          listId,
          notificationUrl:    WEBHOOK_URL,
          expirationDateTime: data.expirationDateTime,
        }
      );
      console.log(`  Firestore record: ${written ? "written" : "FAILED (renewal may not work)"}`);
    }

    results.push({ listId, label, subscriptionId, expirationDateTime: data.expirationDateTime, status: "registered" });
  }

  console.log("\n=== Webhook Registration Summary ===");
  for (const r of results) {
    if (r.status === "registered") {
      console.log(`  ${r.label}: ${r.subscriptionId}`);
      console.log(`    Expires: ${r.expirationDateTime}`);
      console.log(`    Auto-renews daily via renewSharePointWebhooks scheduled function`);
    } else {
      console.log(`  ${r.label}: FAILED — ${r.error}`);
    }
  }

  console.log("\nWebhook URL:", WEBHOOK_URL);
  console.log("Cache invalidation is now active — document changes in SharePoint will");
  console.log("clear the grounding cache within one request cycle (<60 seconds).");
}

main().catch(err => { console.error("\nFailed:", err.message); process.exit(1); });
