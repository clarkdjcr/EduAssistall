#!/usr/bin/env node
/**
 * One-time SharePoint structure provisioning for EduAssist.
 *
 * Auth strategy: device code flow (delegated as admin user). This sidesteps
 * the SharePoint service-principal permission bootstrap problem — the admin
 * user already has full site control so no prior app grant is required.
 * After provisioning it also grants the app service principal site-level
 * owner access so Cloud Functions can use app-only auth at runtime.
 *
 * Prerequisites:
 *   1. Create the "EduAssist" Communication site at https://5h1yp7.sharepoint.com
 *   2. In Entra app registration → Authentication: set "Allow public client flows" = Yes
 *   3. Export env vars and run:
 *        node scripts/setup-sharepoint.js
 *
 * Required env vars:
 *   AZURE_TENANT_ID      – Directory (tenant) ID
 *   AZURE_CLIENT_ID      – Application (client) ID
 *   AZURE_CLIENT_SECRET  – Client secret (used only for the app-only grant step)
 */

const TENANT_ID     = process.env.AZURE_TENANT_ID;
const CLIENT_ID     = process.env.AZURE_CLIENT_ID;
const CLIENT_SECRET = process.env.AZURE_CLIENT_SECRET;
const TENANT_DOMAIN = "5h1yp7.sharepoint.com";
const SITE_PATH     = "EduAssist";

// ---------------------------------------------------------------------------
// Auth — device code flow (delegated, runs as the admin user)
// ---------------------------------------------------------------------------

async function getAdminToken() {
  const dcRes = await fetch(
    `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/devicecode`,
    {
      method: "POST",
      body: new URLSearchParams({
        client_id: CLIENT_ID,
        scope: "https://graph.microsoft.com/Sites.FullControl.All offline_access openid",
      }),
    }
  );
  const dc = await dcRes.json();
  if (!dc.device_code) throw new Error(`Device code error: ${JSON.stringify(dc)}`);

  console.log("\n─────────────────────────────────────────");
  console.log(`  Open:  ${dc.verification_uri}`);
  console.log(`  Code:  ${dc.user_code}`);
  console.log("  Sign in as your tenant admin, then come back here.");
  console.log("─────────────────────────────────────────\n");

  const deadline = Date.now() + dc.expires_in * 1000;
  const pollMs   = (dc.interval || 5) * 1000;

  while (Date.now() < deadline) {
    await new Promise(r => setTimeout(r, pollMs));
    const tokenRes = await fetch(
      `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`,
      {
        method: "POST",
        body: new URLSearchParams({
          grant_type:  "urn:ietf:params:oauth:grant-type:device_code",
          client_id:   CLIENT_ID,
          device_code: dc.device_code,
        }),
      }
    );
    const data = await tokenRes.json();
    if (data.access_token) {
      console.log("  Authenticated.\n");
      return data.access_token;
    }
    if (data.error && data.error !== "authorization_pending") {
      throw new Error(`Token poll error: ${data.error}: ${data.error_description}`);
    }
    process.stdout.write(".");
  }
  throw new Error("Device code flow timed out — run the script again.");
}

// App-only token used solely for the service-principal grant step.
async function getAppToken() {
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
  if (!data.access_token) throw new Error(`App token error: ${JSON.stringify(data)}`);
  return data.access_token;
}

// ---------------------------------------------------------------------------
// Graph helpers
// ---------------------------------------------------------------------------

async function graph(token, method, path, body) {
  const res = await fetch(`https://graph.microsoft.com/v1.0${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Graph ${method} ${path} → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

async function getSiteId(token) {
  const data = await graph(token, "GET", `/sites/${TENANT_DOMAIN}:/sites/${SITE_PATH}`);
  return data.id;
}

async function createLibrary(token, siteId, displayName, description) {
  try {
    console.log(`  Creating library: ${displayName}`);
    const data = await graph(token, "POST", `/sites/${siteId}/lists`, {
      displayName,
      description,
      list: { template: "documentLibrary" },
    });
    return data.id;
  } catch (err) {
    if (err.message.includes("409") || err.message.includes("nameAlreadyExists")) {
      console.log(`  Library "${displayName}" already exists — fetching existing ID.`);
      const existing = await graph(token, "GET", `/sites/${siteId}/lists?$filter=displayName eq '${displayName}'`);
      return existing.value[0].id;
    }
    throw err;
  }
}

async function addColumn(token, siteId, listId, column) {
  try {
    await graph(token, "POST", `/sites/${siteId}/lists/${listId}/columns`, column);
  } catch (err) {
    if (err.message.includes("409") || err.message.includes("nameAlreadyExists")) {
      // Column exists from a previous partial run — skip.
      return;
    }
    throw err;
  }
}

// Grant the app service principal owner access to the site so Cloud Functions
// can use app-only auth at runtime without hitting the same 403.
async function grantAppSiteAccess(adminToken, siteId) {
  console.log("  Granting app service principal site-level owner access...");
  try {
    await graph(adminToken, "POST", `/sites/${siteId}/permissions`, {
      roles: ["owner"],
      grantedToIdentities: [{
        application: {
          id:          CLIENT_ID,
          displayName: "EduAssist Dev",
        },
      }],
    });
    console.log("  Done — app-only auth will work for Cloud Functions.\n");
  } catch (err) {
    // Non-fatal: provisioning continues; runtime auth may need manual fix.
    console.warn(`  Warning: could not grant app site access: ${err.message}`);
    console.warn("  Cloud Functions may need manual permission grant before runtime use.\n");
  }
}

// ---------------------------------------------------------------------------
// Column definitions
// ---------------------------------------------------------------------------

const GRADE_COLUMN = {
  name: "GradeLevel", displayName: "Grade Level",
  choice: { allowTextEntry: false, choices: ["K","1","2","3","4","5","6","7","8","9","10","11","12"] },
};
const SUBJECT_COLUMN = {
  name: "Subject", displayName: "Subject",
  choice: { allowTextEntry: true, choices: ["ELA","Math","Science","Social Studies","Art","Music","PE","Technology","Other"] },
};
const STANDARD_COLUMN  = { name: "Standard",       displayName: "Standard",        text: { maxLength: 100 } };
const SCHOOL_COLUMN    = { name: "School",          displayName: "School",          text: { maxLength: 100 } };
const TERM_COLUMN = {
  name: "Term", displayName: "Term",
  choice: { allowTextEntry: false, choices: ["Fall","Spring","Summer","Full Year"] },
};
const DOC_TYPE_COLUMN = {
  name: "DocumentType", displayName: "Document Type",
  choice: { allowTextEntry: false, choices: ["LessonPlan","ParentLetter","IncidentReport","ProgressReport","Other"] },
};
const APPROVAL_COLUMN = {
  name: "ApprovalStatus", displayName: "Approval Status",
  defaultValue: { value: "Draft" },
  choice: { allowTextEntry: false, choices: ["Draft","PendingApproval","Approved","Rejected"] },
};

// ---------------------------------------------------------------------------
// Library specs
// ---------------------------------------------------------------------------

const LIBRARIES = [
  {
    displayName: "Curriculum",
    description: "District curriculum, standards documents, and instructional resources. Teacher and admin read; admin write.",
    columns: [GRADE_COLUMN, SUBJECT_COLUMN, STANDARD_COLUMN, SCHOOL_COLUMN, TERM_COLUMN],
  },
  {
    displayName: "OfficialDocuments",
    description: "AI-generated official documents (lesson plans, parent letters, reports) that have passed the human approval workflow. Append-only for the application service account.",
    columns: [GRADE_COLUMN, SUBJECT_COLUMN, SCHOOL_COLUMN, TERM_COLUMN, DOC_TYPE_COLUMN, APPROVAL_COLUMN],
  },
  {
    displayName: "StudentContent",
    description: "Student-safe curated content. Student read; teacher and admin write. Grounding source for FR-S4/S5/S6 AI features.",
    columns: [GRADE_COLUMN, SUBJECT_COLUMN, STANDARD_COLUMN, SCHOOL_COLUMN],
  },
  {
    displayName: "Policies",
    description: "District policies and compliance documents. All staff read; admin write.",
    columns: [SCHOOL_COLUMN],
  },
];

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  if (!TENANT_ID || !CLIENT_ID || !CLIENT_SECRET) {
    console.error("Missing required env vars. Set AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET.");
    process.exit(1);
  }

  console.log("Step 1 of 3: Authenticate as tenant admin (device code flow)");
  const adminToken = await getAdminToken();

  console.log(`Step 2 of 3: Resolving site /sites/${SITE_PATH}`);
  const siteId = await getSiteId(adminToken);
  console.log(`  Site ID: ${siteId}\n`);

  await grantAppSiteAccess(adminToken, siteId);

  console.log("Step 3 of 3: Creating libraries and columns\n");
  const results = {};

  for (const lib of LIBRARIES) {
    const listId = await createLibrary(adminToken, siteId, lib.displayName, lib.description);
    console.log(`  List ID: ${listId}`);
    for (const col of lib.columns) {
      process.stdout.write(`    Adding column: ${col.displayName} ... `);
      await addColumn(adminToken, siteId, listId, col);
      console.log("done");
    }
    results[lib.displayName] = listId;
    console.log();
  }

  console.log("=== Provisioning complete ===");
  console.log("Save these library IDs for Cloud Function config:\n");
  for (const [name, id] of Object.entries(results)) {
    console.log(`  ${name.padEnd(20)} ${id}`);
  }
  console.log(`\n  Site ID: ${siteId}`);
  console.log("\nNext step — set as Firebase secrets:");
  console.log("  firebase functions:secrets:set SHAREPOINT_SITE_ID");
  console.log("  firebase functions:secrets:set SHAREPOINT_CURRICULUM_LIST_ID");
  console.log("  firebase functions:secrets:set SHAREPOINT_OFFICIAL_DOCS_LIST_ID");
  console.log("  firebase functions:secrets:set SHAREPOINT_STUDENT_CONTENT_LIST_ID");
}

main().catch(err => {
  console.error("\nFailed:", err.message);
  process.exit(1);
});
