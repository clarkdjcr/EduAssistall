import SwiftUI

// MARK: - Main View

struct ITAdminSetupView: View {
    let profile: UserProfile

    @State private var tenantDomain  = ""
    @State private var siteUrl       = ""
    @State private var verification: CloudFunctionService.SetupVerificationResult?
    @State private var isVerifying   = false
    @State private var verifyError: String?
    @State private var isRegisteringWebhooks = false
    @State private var webhookResults: [CloudFunctionService.WebhookRegistrationResult]?
    @State private var webhookError: String?
    @State private var savedBanner   = false

    private let projectId = "eduassist-b1f49"

    var body: some View {
        List {
            adminIdentitySection
            tenantInputSection
            if let v = verification {
                connectionStatusSection(v)
                coreServicesSection(v)
                microsoftSection(v)
                if !v.discoveredLists.isEmpty {
                    discoveredListsSection(v.discoveredLists)
                }
                sharePointListsSection(v)
            } else if isVerifying {
                Section {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Verifying configuration…").foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else if let err = verifyError {
                Section {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
            }
            actionsSection
            featureMatrixSection
            cliCommandsSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
        .navigationTitle("IT Admin Setup")
        .inlineNavigationTitle()
        .task { await verify() }
        .overlay(alignment: .bottom) {
            if savedBanner {
                Text("Webhooks registered")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(Color.green)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: savedBanner)
    }

    // MARK: - Admin Identity

    private var adminIdentitySection: some View {
        Section {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.displayName).font(.headline)
                    Text(profile.email).font(.caption).foregroundStyle(.secondary)
                    Text("IT Administrator").font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.purple)
                        .clipShape(Capsule())
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Verified IT Administrator")
        }
    }

    // MARK: - Tenant Input

    private var tenantInputSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Microsoft 365 Tenant Domain").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. contoso.onmicrosoft.com", text: $tenantDomain)
                    .urlInput()
            }
            .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("SharePoint Site URL").font(.caption).foregroundStyle(.secondary)
                TextField("e.g. https://contoso.sharepoint.com/sites/education", text: $siteUrl)
                    .urlInput()
            }
            .padding(.vertical, 2)
        } header: {
            Text("District Configuration")
        } footer: {
            Text("These values generate the exact setup commands below. They are not stored — only the Firebase secrets are used at runtime.")
        }
    }

    // MARK: - Connection Status

    private func connectionStatusSection(_ v: CloudFunctionService.SetupVerificationResult) -> some View {
        Section {
            StatusRow(label: "Claude AI (Anthropic)",     ok: v.secrets.coreAIReady,              icon: "brain.head.profile")
            StatusRow(label: "Email Alerts (SendGrid)",   ok: v.secrets.emailReady,               icon: "envelope.badge.shield.half.filled.fill")
            StatusRow(label: "Azure AD / Entra ID",       ok: v.azureConnected,                   icon: "building.columns.fill",
                      detail: v.azureError)
            StatusRow(label: "SharePoint Site",           ok: v.sharePointSiteAccessible,          icon: "folder.badge.gearshape",
                      detail: v.sharePointError)
            HStack {
                Image(systemName: v.overallHealthy ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(v.overallHealthy ? .green : .orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(v.overallHealthy ? "All core services operational" : "Setup incomplete")
                        .font(.subheadline.bold())
                        .foregroundStyle(v.overallHealthy ? .green : .orange)
                    if let ts = isoTimestamp(v.checkedAt) {
                        Text("Checked \(ts)").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Connection Status")
        }
    }

    // MARK: - Core Services

    private func coreServicesSection(_ v: CloudFunctionService.SetupVerificationResult) -> some View {
        Section {
            SecretRow(name: "ANTHROPIC_API_KEY",
                      configured: v.secrets.anthropicKey,
                      purpose: "Powers the student AI companion, lesson plan generator, and parent letter generator.",
                      command: "firebase functions:secrets:set ANTHROPIC_API_KEY --project \(projectId)")

            SecretRow(name: "SENDGRID_API_KEY",
                      configured: v.secrets.sendgridKey,
                      purpose: "Sends counselor distress alerts, daily teacher digests, bulk student invitations, and parental consent emails.",
                      command: "firebase functions:secrets:set SENDGRID_API_KEY --project \(projectId)")
        } header: {
            Text("Firebase Core Services")
        } footer: {
            Text("These secrets are stored in Firebase Secret Manager and never embedded in the app binary.")
        }
    }

    // MARK: - Microsoft Entra ID

    private func microsoftSection(_ v: CloudFunctionService.SetupVerificationResult) -> some View {
        Section {
            SecretRow(name: "AZURE_TENANT_ID",
                      configured: v.secrets.azureTenantId,
                      purpose: "Your Microsoft 365 directory (tenant) ID. Found in Azure portal → Azure Active Directory → Overview.",
                      command: "firebase functions:secrets:set AZURE_TENANT_ID --project \(projectId)")

            SecretRow(name: "AZURE_CLIENT_ID",
                      configured: v.secrets.azureClientId,
                      purpose: "Application (client) ID of the \"EduAssist Integration\" Azure app registration.",
                      command: "firebase functions:secrets:set AZURE_CLIENT_ID --project \(projectId)")

            SecretRow(name: "AZURE_CLIENT_SECRET",
                      configured: v.secrets.azureClientSecret,
                      purpose: "Client secret value from Certificates & secrets. Copy immediately — it is only shown once.",
                      command: "firebase functions:secrets:set AZURE_CLIENT_SECRET --project \(projectId)")

            if !tenantDomain.isEmpty || !siteUrl.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Graph Explorer — Get Site ID")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    let domain = tenantDomain.isEmpty ? "<your-tenant>.sharepoint.com" : tenantDomain.replacingOccurrences(of: ".onmicrosoft.com", with: ".sharepoint.com")
                    let sitePath = siteUrl.isEmpty
                        ? "/sites/<your-site>"
                        : URL(string: siteUrl).flatMap { url in
                            let path = url.path
                            return path.isEmpty ? nil : path
                          } ?? "/sites/<your-site>"
                    let graphUrl = "GET https://graph.microsoft.com/v1.0/sites/\(domain):\(sitePath)"
                    HStack(spacing: 8) {
                        Text(graphUrl)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        CopyButton2(value: graphUrl)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Microsoft Entra ID (Azure AD)")
        } footer: {
            Text("EduAssist uses a service-to-service app registration. Required Graph API permissions: Sites.Read.All, Sites.ReadWrite.All, Files.ReadWrite.All — with admin consent granted.")
        }
    }

    // MARK: - SharePoint Lists

    private func sharePointListsSection(_ v: CloudFunctionService.SetupVerificationResult) -> some View {
        Section {
            SecretRow(name: "SHAREPOINT_SITE_ID",
                      configured: v.secrets.sharepointSiteId,
                      purpose: "GUID of your SharePoint site. Use the Graph Explorer command above to look it up.",
                      command: "firebase functions:secrets:set SHAREPOINT_SITE_ID --project \(projectId)",
                      listStatus: v.sharePointSiteAccessible ? .ok : (v.secrets.sharepointSiteId ? .error : .notSet))

            SecretRow(name: "SHAREPOINT_CURRICULUM_LIST_ID",
                      configured: v.secrets.curriculumListId,
                      purpose: "Document library containing district curriculum materials. Used to ground lesson plan generation with your actual scope and sequence.",
                      command: "firebase functions:secrets:set SHAREPOINT_CURRICULUM_LIST_ID --project \(projectId)",
                      listStatus: v.lists.curriculum ? .ok : (v.secrets.curriculumListId ? .error : .notSet))

            SecretRow(name: "SHAREPOINT_OFFICIAL_DOCS_LIST_ID",
                      configured: v.secrets.officialDocsListId,
                      purpose: "Document library where AI-generated lesson plans and parent letters are saved for district approval. Set ApprovalStatus to PendingApproval automatically.",
                      command: "firebase functions:secrets:set SHAREPOINT_OFFICIAL_DOCS_LIST_ID --project \(projectId)",
                      listStatus: v.lists.officialDocs ? .ok : (v.secrets.officialDocsListId ? .error : .notSet))

            SecretRow(name: "SHAREPOINT_STUDENT_CONTENT_LIST_ID",
                      configured: v.secrets.studentContentListId,
                      purpose: "List of curriculum-aligned content items used to ground the student AI companion responses.",
                      command: "firebase functions:secrets:set SHAREPOINT_STUDENT_CONTENT_LIST_ID --project \(projectId)",
                      listStatus: v.lists.studentContent ? .ok : (v.secrets.studentContentListId ? .error : .notSet),
                      optional: true)

            SecretRow(name: "SHAREPOINT_POLICIES_LIST_ID",
                      configured: v.secrets.policiesListId,
                      purpose: "List of district policy document titles injected into the student AI companion system prompt to enforce district rules.",
                      command: "firebase functions:secrets:set SHAREPOINT_POLICIES_LIST_ID --project \(projectId)",
                      listStatus: v.lists.policies ? .ok : (v.secrets.policiesListId ? .error : .notSet),
                      optional: true)
        } header: {
            Text("SharePoint Libraries")
        } footer: {
            Text("Get list IDs via: GET https://graph.microsoft.com/v1.0/sites/{siteId}/lists — note the \"id\" field for each library. Optional lists degrade gracefully if absent.")
        }
    }

    // MARK: - Discovered Lists

    private func discoveredListsSection(_ lists: [CloudFunctionService.DiscoveredList]) -> some View {
        Section {
            ForEach(lists) { list in
                VStack(alignment: .leading, spacing: 6) {
                    Text(list.name)
                        .font(.subheadline.bold())
                    HStack(spacing: 8) {
                        Text(list.id)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        CopyButton2(value: list.id)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Lists Found on Site — tap to copy ID")
        } footer: {
            Text("Use these IDs with the firebase functions:secrets:set commands below to connect each library.")
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section {
            Button {
                Task { await verify() }
            } label: {
                HStack {
                    Spacer()
                    if isVerifying {
                        ProgressView()
                        Text("Verifying…").padding(.leading, 8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Verify All Connections")
                    }
                    Spacer()
                }
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            }
            .disabled(isVerifying)

            if profile.role == .admin {
                Button {
                    Task { await registerWebhooks() }
                } label: {
                    HStack {
                        Spacer()
                        if isRegisteringWebhooks {
                            ProgressView()
                            Text("Registering…").padding(.leading, 8)
                        } else {
                            Image(systemName: "bell.badge.waveform.fill")
                            Text("Register SharePoint Webhooks")
                        }
                        Spacer()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                }
                .disabled(isRegisteringWebhooks)

                if let results = webhookResults {
                    ForEach(results, id: \.listId) { r in
                        HStack(spacing: 8) {
                            Image(systemName: r.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(r.succeeded ? .green : .red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.succeeded ? "Registered" : "Failed").font(.caption.bold())
                                Text(r.listId).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
                                if let err = r.error { Text(err).font(.caption2).foregroundStyle(.red) }
                            }
                        }
                    }
                }

                if let err = webhookError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange).font(.caption)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle").foregroundStyle(.blue).font(.caption)
                    Text("Webhook registration requires an account with the Admin role. Contact your Firebase project owner.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Actions")
        } footer: {
            Text("SharePoint webhooks notify EduAssist when curriculum documents change so AI responses stay current. They renew automatically every 24 hours.")
        }
    }

    // MARK: - Feature → Service Matrix

    private var featureMatrixSection: some View {
        Section {
            FeatureRow(feature: "Student AI Companion",
                       firebase: "Chat history, user profiles",
                       claude: "Responses",
                       sharePoint: "Curriculum grounding, policies",
                       sendGrid: nil)

            FeatureRow(feature: "Lesson Plan Generator",
                       firebase: "Audit log",
                       claude: "Content generation",
                       sharePoint: "Read curriculum → write output",
                       sendGrid: nil)

            FeatureRow(feature: "Parent Letter Generator",
                       firebase: "Student progress data",
                       claude: "Letter generation",
                       sharePoint: "Write to OfficialDocuments",
                       sendGrid: nil)

            FeatureRow(feature: "Safety Alerts",
                       firebase: "Event records",
                       claude: "Distress detection",
                       sharePoint: nil,
                       sendGrid: "Email counselor")

            FeatureRow(feature: "Daily Teacher Digest",
                       firebase: "Progress & alert data",
                       claude: nil,
                       sharePoint: nil,
                       sendGrid: "Email digest")

            FeatureRow(feature: "Bulk Student Invitations",
                       firebase: "Auth + roster",
                       claude: nil,
                       sharePoint: nil,
                       sendGrid: "Invite emails")

            FeatureRow(feature: "Parental Consent (COPPA)",
                       firebase: "Auth + consent status",
                       claude: nil,
                       sharePoint: nil,
                       sendGrid: "Consent email")

            FeatureRow(feature: "Topic Boundaries",
                       firebase: "districtConfig collection",
                       claude: nil,
                       sharePoint: nil,
                       sendGrid: nil)

            FeatureRow(feature: "Real-Time Curriculum Sync",
                       firebase: nil,
                       claude: nil,
                       sharePoint: "Webhooks → cache invalidation",
                       sendGrid: nil)

            FeatureRow(feature: "Push Notifications",
                       firebase: "FCM tokens + delivery",
                       claude: nil,
                       sharePoint: nil,
                       sendGrid: nil)

            FeatureRow(feature: "AI Recommendations",
                       firebase: "Storage + delivery",
                       claude: "Generation",
                       sharePoint: nil,
                       sendGrid: nil)
        } header: {
            Text("Feature → Service Map")
        } footer: {
            Text("Each feature degrades gracefully: lesson plans still generate without SharePoint grounding; companion still works without curriculum lists.")
        }
    }

    // MARK: - CLI Commands Reference

    private var cliCommandsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Required Graph API Permissions (app registration)").font(.caption.bold()).foregroundStyle(.secondary)
                ForEach(["Sites.Read.All", "Sites.ReadWrite.All", "Files.ReadWrite.All"], id: \.self) { perm in
                    HStack(spacing: 6) {
                        Image(systemName: "key.fill").font(.caption2).foregroundStyle(.blue)
                        Text(perm).font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Deploy functions after setting secrets").font(.caption.bold()).foregroundStyle(.secondary)
                let deployCmd = "cd EduAssistall && firebase deploy --only functions --project \(projectId)"
                HStack(spacing: 8) {
                    Text(deployCmd)
                        .font(.system(.caption, design: .monospaced))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    CopyButton2(value: deployCmd)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Reference")
        }
    }

    // MARK: - Actions

    private func verify() async {
        isVerifying = true
        verifyError = nil
        do {
            verification = try await CloudFunctionService.shared.verifySharePointSetup()
        } catch {
            verifyError = error.localizedDescription
        }
        isVerifying = false
    }

    private func registerWebhooks() async {
        isRegisteringWebhooks = true
        webhookResults = nil
        webhookError = nil
        do {
            webhookResults = try await CloudFunctionService.shared.registerSharePointWebhooks()
            if webhookResults?.allSatisfy(\.succeeded) == true {
                savedBanner = true
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    savedBanner = false
                }
            }
        } catch {
            webhookError = error.localizedDescription
        }
        isRegisteringWebhooks = false
    }

    private func isoTimestamp(_ iso: String) -> String? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return nil }
        let r = RelativeDateTimeFormatter()
        r.unitsStyle = .abbreviated
        return r.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

private struct StatusRow: View {
    let label: String
    let ok: Bool
    let icon: String
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(ok ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline)
                if let d = detail, !ok {
                    Text(d).font(.caption2).foregroundStyle(.red)
                }
            }
            Spacer()
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ok ? .green : .orange)
        }
        .padding(.vertical, 2)
    }
}

private enum ListCheckStatus { case ok, error, notSet }

private struct SecretRow: View {
    let name: String
    let configured: Bool
    let purpose: String
    let command: String
    var listStatus: ListCheckStatus = .notSet
    var optional: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .frame(width: 20)
                Text(name)
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundStyle(.primary)
                Spacer()
                if optional {
                    Text("Optional").font(.caption2).foregroundStyle(.secondary)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            Text(purpose)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Text(command)
                    .font(.system(.caption2, design: .monospaced))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                CopyButton2(value: command)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: String {
        switch listStatus {
        case .ok:     return "checkmark.circle.fill"
        case .error:  return "exclamationmark.circle.fill"
        case .notSet: return configured ? "questionmark.circle.fill" : "circle.dashed"
        }
    }

    private var statusColor: Color {
        switch listStatus {
        case .ok:     return .green
        case .error:  return .red
        case .notSet: return configured ? .yellow : .secondary
        }
    }
}

private struct FeatureRow: View {
    let feature: String
    let firebase: String?
    let claude: String?
    let sharePoint: String?
    let sendGrid: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(feature).font(.subheadline.bold())
            HStack(spacing: 0) {
                if let v = firebase    { Chip(label: "Firebase",    value: v, color: .orange) }
                if let v = claude      { Chip(label: "Claude AI",   value: v, color: .blue) }
                if let v = sharePoint  { Chip(label: "SharePoint",  value: v, color: .green) }
                if let v = sendGrid    { Chip(label: "SendGrid",    value: v, color: .purple) }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct Chip: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(color)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.trailing, 6).padding(.bottom, 4)
    }
}

private struct CopyButton2: View {
    let value: String
    @State private var copied = false

    var body: some View {
        Button {
            copyToClipboard(value)
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.subheadline)
                .foregroundStyle(copied ? .green : .blue)
                .animation(.easeInOut(duration: 0.15), value: copied)
        }
        .buttonStyle(.plain)
    }
}
