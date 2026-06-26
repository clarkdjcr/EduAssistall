import SwiftUI

// IT Administrator service health dashboard.
// Shows live status for every attached service; reads latency stats, backup log,
// and safety benchmark results from Firestore; uses verifySharePointSetup() for
// secrets/connectivity status.
struct ServiceHealthDashboardView: View {
    let profile: UserProfile

    @State private var isLoading = true
    @State private var lastRefresh: Date?
    @State private var connectivity: Bool = true

    // Service verification (secrets + SharePoint connectivity)
    @State private var verification: CloudFunctionService.SetupVerificationResult?
    @State private var verifyError: String?

    // Firestore health snapshots
    @State private var latency: FirestoreService.LatencySnapshot?
    @State private var backup: FirestoreService.BackupLogEntry?
    @State private var benchmark: FirestoreService.SafetyBenchmarkEntry?

    // Document backend (firebase or sharepoint)
    @State private var documentBackend: String = "firebase"

    private var overallStatus: HealthStatus {
        guard !isLoading else { return .unknown }
        guard connectivity else { return .critical }
        guard let v = verification else { return .unknown }
        if !v.secrets.coreAIReady { return .critical }
        if v.overallHealthy == false && documentBackend == "sharepoint" { return .degraded }
        if latency?.breachingTarget == true { return .degraded }
        if backup?.succeeded == false { return .degraded }
        return .healthy
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overallBanner
                coreServicesSection
                performanceSection
                documentBackendSection
                safetyComplianceSection
                actionsSection
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Service Health")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isLoading {
                    ProgressView()
                } else {
                    Button { Task { await refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task { await refresh() }
    }

    // MARK: - Overall banner

    private var overallBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: overallStatus.icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(overallStatus.color)

            VStack(alignment: .leading, spacing: 4) {
                Text(overallStatus.title)
                    .font(.title3.bold())
                    .foregroundStyle(overallStatus.color)
                Text(overallStatus.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let ts = lastRefresh {
                    Text("Last checked \(ts, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(18)
        .background(overallStatus.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(overallStatus.color.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Core Services

    private var coreServicesSection: some View {
        DashboardCard(title: "Core Services", icon: "server.rack") {
            VStack(spacing: 2) {
                ServiceRow(
                    label: "Firebase / Firestore",
                    icon: "flame.fill",
                    status: connectivity ? .ok : .error,
                    detail: connectivity ? "Connected" : "Offline"
                )
                Divider().padding(.leading, 42)
                ServiceRow(
                    label: "Claude AI (Anthropic)",
                    icon: "brain.head.profile",
                    status: verification.map { $0.secrets.coreAIReady ? .ok : .error } ?? .unknown,
                    detail: verification?.secrets.districtApiKeyConfigured == true
                        ? "District key active"
                        : verification?.secrets.anthropicKey == true
                            ? "Shared key active"
                            : verification != nil ? "Key not configured" : nil
                )
                Divider().padding(.leading, 42)
                ServiceRow(
                    label: "Email Alerts (SendGrid)",
                    icon: "envelope.badge.shield.half.filled.fill",
                    status: verification.map { $0.secrets.emailReady ? .ok : .warning } ?? .unknown,
                    detail: verification.map { $0.secrets.emailReady ? "Configured" : "Not configured — alerts disabled" }
                )
                Divider().padding(.leading, 42)
                ServiceRow(
                    label: "Push Notifications (FCM)",
                    icon: "bell.badge.fill",
                    status: profile.fcmToken != nil ? .ok : .warning,
                    detail: profile.fcmToken != nil ? "Token registered" : "No FCM token on this device"
                )
            }
        }
    }

    // MARK: - Performance

    @ViewBuilder
    private var performanceSection: some View {
        DashboardCard(title: "Performance", icon: "gauge.with.dots.needle.67percent") {
            if let l = latency {
                VStack(spacing: 2) {
                    LatencyRow(label: "Median (p50)", ms: l.p50Ms, threshold: 500)
                    Divider().padding(.leading, 42)
                    LatencyRow(label: "95th percentile", ms: l.p95Ms, threshold: 2000, isTarget: true)
                    Divider().padding(.leading, 42)
                    LatencyRow(label: "99th percentile", ms: l.p99Ms, threshold: 4000)
                    if l.breachingTarget {
                        Divider().padding(.leading, 42)
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 28)
                            Text("p95 exceeds 2 s target — consider reviewing Cloud Function cold starts or query indexes.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.vertical, 6)
                    }
                }
                HStack {
                    Spacer()
                    Text("Updated \(l.timestamp, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            } else {
                EmptyDataRow(message: "No latency data yet — stats are computed hourly by the server.")
            }
        }
    }

    // MARK: - Document Backend

    private var documentBackendSection: some View {
        DashboardCard(title: "Document Backend", icon: "folder.badge.gearshape") {
            VStack(spacing: 2) {
                HStack(spacing: 12) {
                    Image(systemName: documentBackend == "sharepoint" ? "building.columns.fill" : "flame.fill")
                        .font(.title3)
                        .foregroundStyle(documentBackend == "sharepoint" ? .blue : .orange)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(documentBackend == "sharepoint" ? "SharePoint (Microsoft 365)" : "Firebase Storage")
                            .font(.subheadline.bold())
                        Text(documentBackend == "sharepoint"
                             ? "AI documents stored in SharePoint with district approval flow."
                             : "AI documents stored in Firebase. No Microsoft 365 required.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)

                if documentBackend == "sharepoint" {
                    Divider().padding(.leading, 42)
                    ServiceRow(
                        label: "Azure AD / Entra ID",
                        icon: "building.columns.fill",
                        status: verification.map { $0.azureConnected ? .ok : .error } ?? .unknown,
                        detail: verification?.azureError
                    )
                    Divider().padding(.leading, 42)
                    ServiceRow(
                        label: "SharePoint Site",
                        icon: "internaldrive.fill",
                        status: verification.map { $0.sharePointSiteAccessible ? .ok : .error } ?? .unknown,
                        detail: verification?.sharePointError
                    )
                } else {
                    Divider().padding(.leading, 42)
                    ServiceRow(
                        label: "SharePoint",
                        icon: "building.columns",
                        status: .notApplicable,
                        detail: "Optional — requires Microsoft 365 tenant. Configure in IT Integration settings."
                    )
                }
            }
        }
    }

    // MARK: - Safety & Compliance

    private var safetyComplianceSection: some View {
        DashboardCard(title: "Safety & Compliance", icon: "shield.checkerboard") {
            VStack(spacing: 2) {
                // Safety benchmark
                if let b = benchmark {
                    HStack(spacing: 12) {
                        Image(systemName: b.passed ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .font(.title3)
                            .foregroundStyle(b.passed ? .green : .red)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Safety Classifier Benchmark")
                                .font(.subheadline.bold())
                            HStack(spacing: 10) {
                                BenchmarkChip(label: "TPR", value: b.tpr, good: b.tpr >= 0.995)
                                BenchmarkChip(label: "FPR", value: b.fpr, good: b.fpr < 0.005)
                                Text("n=\(b.corpusSize)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(b.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: b.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(b.passed ? .green : .red)
                    }
                    .padding(.vertical, 6)
                } else {
                    EmptyDataRow(message: "No benchmark run recorded yet.")
                }

                Divider().padding(.leading, 42)

                // Backup log
                if let bk = backup {
                    HStack(spacing: 12) {
                        Image(systemName: bk.succeeded ? "externaldrive.badge.checkmark" : "externaldrive.badge.xmark")
                            .font(.title3)
                            .foregroundStyle(bk.succeeded ? .green : .red)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Daily Firestore Backup")
                                .font(.subheadline.bold())
                            Text(bk.succeeded ? "Backup completed successfully" : "Backup failed — check drBackupLog")
                                .font(.caption)
                                .foregroundStyle(bk.succeeded ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))
                            Text(bk.timestamp, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: bk.succeeded ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(bk.succeeded ? .green : .red)
                    }
                    .padding(.vertical, 6)
                } else {
                    EmptyDataRow(message: "No backup records yet.")
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                ITAdminSetupView(profile: profile)
            } label: {
                Label("Full IT Integration Setup", systemImage: "server.rack")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            if let err = verifyError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Data loading

    private func refresh() async {
        isLoading = true
        verifyError = nil
        connectivity = ConnectivityService.shared.isOnline

        // Load document backend selection (nil in DistrictConfig = legacy default = sharepoint)
        let districtId = profile.districtId ?? "default"
        if let config = try? await FirestoreService.shared.fetchDistrictConfig(districtId: districtId) {
            documentBackend = config.documentBackend ?? "sharepoint"
        }

        // Parallel fetches
        async let latencyFetch    = FirestoreService.shared.fetchLatencySnapshot()
        async let backupFetch     = FirestoreService.shared.fetchLatestBackupLog()
        async let benchmarkFetch  = FirestoreService.shared.fetchLatestSafetyBenchmark()
        async let verifyFetch: CloudFunctionService.SetupVerificationResult? = {
            do { return try await CloudFunctionService.shared.verifySharePointSetup() }
            catch { return nil }
        }()

        latency       = try? await latencyFetch
        backup        = try? await backupFetch
        benchmark     = try? await benchmarkFetch
        verification  = await verifyFetch

        lastRefresh = Date()
        isLoading = false
    }
}

// MARK: - Health Status

private enum HealthStatus {
    case healthy, degraded, critical, unknown

    var title: String {
        switch self {
        case .healthy:  return "All Systems Operational"
        case .degraded: return "Degraded — Attention Needed"
        case .critical: return "Critical — Action Required"
        case .unknown:  return "Checking…"
        }
    }

    var subtitle: String {
        switch self {
        case .healthy:  return "All attached services are reachable and within performance targets."
        case .degraded: return "One or more services are misconfigured or slow. App features may be limited."
        case .critical: return "Core services are unreachable. Students cannot use AI features."
        case .unknown:  return "Fetching service status…"
        }
    }

    var icon: String {
        switch self {
        case .healthy:  return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        case .unknown:  return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .healthy:  return .green
        case .degraded: return .orange
        case .critical: return .red
        case .unknown:  return .secondary
        }
    }
}

// MARK: - Service Row Status

private enum ServiceStatus { case ok, warning, error, notApplicable, unknown }

// MARK: - Reusable Card

private struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.primary)

            content()
        }
        .padding(16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Service Row

private struct ServiceRow: View {
    let label: String
    let icon: String
    let status: ServiceStatus
    var detail: String?

    private var statusColor: Color {
        switch status {
        case .ok:            return .green
        case .warning:       return .orange
        case .error:         return .red
        case .notApplicable: return .secondary
        case .unknown:       return .secondary
        }
    }

    private var statusIcon: String {
        switch status {
        case .ok:            return "checkmark.circle.fill"
        case .warning:       return "exclamationmark.circle.fill"
        case .error:         return "xmark.circle.fill"
        case .notApplicable: return "minus.circle"
        case .unknown:       return "ellipsis.circle"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline)
                if let d = detail {
                    Text(d)
                        .font(.caption)
                        .foregroundStyle(status == .error ? .red : .secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Latency Row

private struct LatencyRow: View {
    let label: String
    let ms: Double
    let threshold: Double
    var isTarget: Bool = false

    private var color: Color {
        if ms == 0 { return .secondary }
        return ms <= threshold ? .green : (ms <= threshold * 1.5 ? .orange : .red)
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 160, alignment: .leading)
            Spacer()
            HStack(spacing: 4) {
                Text(ms == 0 ? "—" : String(format: "%.0f ms", ms))
                    .font(.subheadline.bold())
                    .foregroundStyle(ms == 0 ? .secondary : color)
                if isTarget && ms > 0 {
                    Text("target ≤ 2 s")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Benchmark Chip

private struct BenchmarkChip: View {
    let label: String
    let value: Double
    let good: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(good ? .green : .red)
            Text(String(format: "%.1f%%", value * 100))
                .font(.caption2)
                .foregroundStyle(good ? .green : .red)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background((good ? Color.green : Color.red).opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Empty Data Row

private struct EmptyDataRow: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.questionmark")
                .foregroundStyle(.secondary)
                .frame(width: 28)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
