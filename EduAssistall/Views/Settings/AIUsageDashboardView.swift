import SwiftUI

struct AIUsageDashboardView: View {
    @State private var stats: CloudFunctionService.AIUsageStats?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading usage data…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let msg = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Retry") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let stats {
                List {
                    todaySection(stats.today)
                    monthSection(stats.month)
                    featureSection(stats.byFeature)
                    latencySection(stats.latency)
                    footerSection(stats.generatedAt)
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("AI Usage")
        .inlineNavigationTitle()
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Sections

    private func todaySection(_ p: CloudFunctionService.AIUsageStats.Period) -> some View {
        Section("Today") {
            UsageStat(label: "AI Calls",       value: "\(p.calls)")
            UsageStat(label: "Input Tokens",   value: p.inputTokens.formatted())
            UsageStat(label: "Output Tokens",  value: p.outputTokens.formatted())
            UsageStat(label: "Grounding Hits", value: groundingRate(p))
            UsageStat(label: "Est. Cost",      value: String(format: "$%.4f", p.estimatedCostUSD))
        }
    }

    private func monthSection(_ p: CloudFunctionService.AIUsageStats.Period) -> some View {
        Section("Last 30 Days") {
            UsageStat(label: "AI Calls",        value: "\(p.calls)")
            UsageStat(label: "Input Tokens",    value: p.inputTokens.formatted())
            UsageStat(label: "Output Tokens",   value: p.outputTokens.formatted())
            UsageStat(label: "Grounding Hits",  value: groundingRate(p))
            UsageStat(label: "Est. Cost (USD)", value: String(format: "$%.2f", p.estimatedCostUSD))
            Text("Based on Claude Sonnet 4.6: $3/MTok input · $15/MTok output")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func featureSection(_ byFeature: [String: Int]) -> some View {
        if !byFeature.isEmpty {
            Section("Calls by Feature") {
                ForEach(byFeature.sorted(by: { $0.value > $1.value }), id: \.key) { feature, count in
                    UsageStat(label: featureDisplayName(feature), value: "\(count)")
                }
            }
        }
    }

    private func latencySection(_ lat: CloudFunctionService.AIUsageStats.LatencyStats) -> some View {
        Section("Latency") {
            if let p50 = lat.p50ms, let p95 = lat.p95ms, let p99 = lat.p99ms {
                UsageStat(label: "p50", value: "\(p50) ms")
                HStack {
                    UsageStat(label: "p95", value: "\(p95) ms")
                    if lat.breachingTarget {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                UsageStat(label: "p99", value: "\(p99) ms")
                if lat.breachingTarget {
                    Text("p95 exceeds 2 s target")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Text("No latency data yet — computed hourly after first AI calls.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func footerSection(_ generatedAt: String) -> some View {
        Section {
            Text("Covers last 30 days, up to 2,000 events. Pull to refresh.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } footer: {
            Text("Generated \(generatedAt)")
                .font(.caption2)
        }
    }

    // MARK: - Helpers

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            stats = try await CloudFunctionService.shared.getAIUsageStats()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func groundingRate(_ p: CloudFunctionService.AIUsageStats.Period) -> String {
        guard p.calls > 0 else { return "—" }
        let pct = Int((Double(p.groundingHits) / Double(p.calls)) * 100)
        return "\(p.groundingHits) (\(pct)%)"
    }

    private func featureDisplayName(_ id: String) -> String {
        switch id {
        case "askCompanion":         return "Student Companion"
        case "generateLessonPlan":   return "Lesson Plan"
        case "generateParentLetter": return "Parent Letter"
        default:                     return id
        }
    }
}

// MARK: - UsageStat row (local to this file — avoids conflict with StudentProgressView.StatRow)

private struct UsageStat: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
