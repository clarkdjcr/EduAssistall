import SwiftUI
import FirebaseFirestore

struct StandardsUpdateReviewView: View {
    @State private var alerts: [StandardsUpdateAlert] = []
    @State private var sources: [PublicStandardsSource] = []
    @State private var selectedStatus = "NeedsReview"
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var actionError: String?
    @State private var actionInProgress = Set<String>()

    private let statusOptions = ["NeedsReview", "Approved", "Rejected"]

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading standards updates...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Retry") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let actionError {
                        Section {
                            Label(actionError, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.subheadline)
                        }
                    }

                    Section {
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(statusOptions, id: \.self) { status in
                                Text(statusLabel(status)).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    reviewQueueSection
                    sourceHealthSection
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Standards Updates")
        .inlineNavigationTitle()
        .task { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var reviewQueueSection: some View {
        let filteredAlerts = alerts.filter { $0.status == selectedStatus }
        Section("\(filteredAlerts.count) \(statusLabel(selectedStatus))") {
            if filteredAlerts.isEmpty {
                Label(emptyText(for: selectedStatus), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredAlerts) { alert in
                    NavigationLink {
                        StandardsUpdateDetailView(
                            alert: alert,
                            isBusy: actionInProgress.contains(alert.id),
                            onDecision: { decision, notes in
                                await decide(alert: alert, decision: decision, notes: notes)
                            }
                        )
                    } label: {
                        StandardsUpdateAlertRow(alert: alert)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sourceHealthSection: some View {
        Section("Monitored Sources") {
            if sources.isEmpty {
                Text("No monitor sources have checked in yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sources) { source in
                    PublicStandardsSourceRow(source: source)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let db = Firestore.firestore()
            async let loadedAlerts = fetchAlerts(db: db)
            async let loadedSources = fetchSources(db: db)
            alerts = try await loadedAlerts
            sources = try await loadedSources
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchAlerts(db: Firestore) async throws -> [StandardsUpdateAlert] {
        let snap = try await db.collection("standardsUpdateAlerts")
            .order(by: "detectedAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        return snap.documents.compactMap { StandardsUpdateAlert(from: $0) }
    }

    private func fetchSources(db: Firestore) async throws -> [PublicStandardsSource] {
        let snap = try await db.collection("publicStandardsSources")
            .order(by: "lastCheckedAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        return snap.documents.compactMap { PublicStandardsSource(from: $0) }
    }

    private func decide(alert: StandardsUpdateAlert, decision: String, notes: String) async {
        actionInProgress.insert(alert.id)
        actionError = nil
        do {
            try await CloudFunctionService.shared.approveStandardsUpdate(
                alertId: alert.id,
                decision: decision,
                notes: notes
            )
            await load()
        } catch {
            actionError = error.localizedDescription
        }
        actionInProgress.remove(alert.id)
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "NeedsReview": return "Needs Review"
        default: return status
        }
    }

    private func emptyText(for status: String) -> String {
        switch status {
        case "NeedsReview": return "No standards changes waiting for review."
        case "Approved": return "No approved standards updates in the latest results."
        case "Rejected": return "No rejected standards updates in the latest results."
        default: return "No standards updates found."
        }
    }
}

private struct StandardsUpdateDetailView: View {
    let alert: StandardsUpdateAlert
    let isBusy: Bool
    let onDecision: (String, String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var notes = ""

    var body: some View {
        List {
            Section("Source") {
                LabeledContent("Title", value: alert.title)
                LabeledContent("Group", value: alert.sourceGroup)
                if let detectedAt = alert.detectedAt {
                    LabeledContent("Detected", value: detectedAt.formatted(date: .abbreviated, time: .shortened))
                }
                if let reviewedAt = alert.reviewedAt {
                    LabeledContent("Reviewed", value: reviewedAt.formatted(date: .abbreviated, time: .shortened))
                }
                Link(destination: alert.url) {
                    Label("Open Source", systemImage: "safari")
                }
            }

            Section("Change") {
                StandardsHashRow(label: "Previous", hash: alert.previousHash)
                StandardsHashRow(label: "Current", hash: alert.currentHash)
                LabeledContent("Bytes", value: alert.byteLength.formatted())
            }

            Section("Excerpt") {
                Text(alert.excerpt.isEmpty ? "No excerpt captured." : alert.excerpt)
                    .font(.callout)
                    .textSelection(.enabled)
            }

            if alert.status == "NeedsReview" {
                Section("Review") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 96)
                }

                Section {
                    if isBusy {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await onDecision("Rejected", notes)
                                    dismiss()
                                }
                            } label: {
                                Label("Reject", systemImage: "xmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)

                            Button {
                                Task {
                                    await onDecision("Approved", notes)
                                    dismiss()
                                }
                            } label: {
                                Label("Approve", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                }
            } else if !alert.reviewNotes.isEmpty {
                Section("Review Notes") {
                    Text(alert.reviewNotes)
                        .font(.callout)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
        .navigationTitle("Update Review")
        .inlineNavigationTitle()
    }
}

private struct StandardsUpdateAlertRow: View {
    let alert: StandardsUpdateAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    Text(alert.sourceGroup)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                chip(statusLabel)
                if let detectedAt = alert.detectedAt {
                    Text(detectedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusLabel: String {
        alert.status == "NeedsReview" ? "Needs Review" : alert.status
    }

    private var iconName: String {
        switch alert.status {
        case "Approved": return "checkmark.circle.fill"
        case "Rejected": return "xmark.circle.fill"
        default: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch alert.status {
        case "Approved": return .green
        case "Rejected": return .red
        default: return .orange
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct PublicStandardsSourceRow: View {
    let source: PublicStandardsSource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: source.lastStatus == "error" ? "exclamationmark.triangle.fill" : "link.circle.fill")
                    .foregroundStyle(source.lastStatus == "error" ? .orange : .blue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    Text(source.url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 8) {
                chip(source.lastStatus.isEmpty ? "Not Checked" : source.lastStatus.capitalized)
                if let lastCheckedAt = source.lastCheckedAt {
                    Text(lastCheckedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if let lastError = source.lastError, !lastError.isEmpty {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct StandardsHashRow: View {
    let label: String
    let hash: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(hash)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }
}

private struct StandardsUpdateAlert: Identifiable {
    let id: String
    let sourceId: String
    let title: String
    let url: URL
    let sourceGroup: String
    let previousHash: String
    let currentHash: String
    let status: String
    let excerpt: String
    let byteLength: Int
    let detectedAt: Date?
    let reviewedAt: Date?
    let reviewedBy: String
    let reviewNotes: String

    init?(from snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let urlString = data["url"] as? String,
              let url = URL(string: urlString) else { return nil }
        id = snapshot.documentID
        sourceId = data["sourceId"] as? String ?? ""
        title = data["title"] as? String ?? urlString
        self.url = url
        sourceGroup = data["sourceGroup"] as? String ?? "public-standards"
        previousHash = data["previousHash"] as? String ?? ""
        currentHash = data["currentHash"] as? String ?? ""
        status = data["status"] as? String ?? "NeedsReview"
        excerpt = data["excerpt"] as? String ?? ""
        byteLength = data["byteLength"] as? Int ?? 0
        detectedAt = (data["detectedAt"] as? Timestamp)?.dateValue()
        reviewedAt = (data["reviewedAt"] as? Timestamp)?.dateValue()
        reviewedBy = data["reviewedBy"] as? String ?? ""
        reviewNotes = data["reviewNotes"] as? String ?? ""
    }
}

private struct PublicStandardsSource: Identifiable {
    let id: String
    let title: String
    let url: URL
    let sourceGroup: String
    let lastStatus: String
    let lastError: String?
    let latestHash: String
    let approvedHash: String
    let lastCheckedAt: Date?

    init?(from snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let urlString = data["url"] as? String,
              let url = URL(string: urlString) else { return nil }
        id = snapshot.documentID
        title = data["title"] as? String ?? urlString
        self.url = url
        sourceGroup = data["sourceGroup"] as? String ?? "public-standards"
        lastStatus = data["lastStatus"] as? String ?? ""
        lastError = data["lastError"] as? String
        latestHash = data["latestHash"] as? String ?? ""
        approvedHash = data["approvedHash"] as? String ?? ""
        lastCheckedAt = (data["lastCheckedAt"] as? Timestamp)?.dateValue()
    }
}
