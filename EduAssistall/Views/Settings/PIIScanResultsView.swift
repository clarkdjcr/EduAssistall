import SwiftUI
import FirebaseFirestore

struct PIIScanLog: Identifiable, Codable {
    var id: String
    var scannedAt: Date
    var windowDays: Int
    var messagesScanned: Int
    var violationsFound: Int
    var remediatedCount: Int
}

struct PIIScanResultsView: View {
    @State private var logs: [PIIScanLog] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if logs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("No scans yet")
                        .font(.title3.bold())
                    Text("The weekly PII scan runs every Sunday at 02:00 UTC.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(logs) { log in
                            PIIScanLogRow(log: log)
                        }
                    } footer: {
                        Text("Any PII found is automatically redacted. Results are kept for audit purposes.")
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("PII Scan Results")
        .inlineNavigationTitle()
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        let db = Firestore.firestore()
        let snap = try? await db.collection("piiScanLogs")
            .order(by: "scannedAt", descending: true)
            .limit(to: 20)
            .getDocuments()
        logs = (snap?.documents.compactMap { doc -> PIIScanLog? in
            var data = doc.data()
            data["id"] = doc.documentID
            return try? Firestore.Decoder().decode(PIIScanLog.self, from: data)
        }) ?? []
        isLoading = false
    }
}

private struct PIIScanLogRow: View {
    let log: PIIScanLog

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.scannedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.bold())
                Spacer()
                if log.violationsFound > 0 {
                    Text("\(log.violationsFound) violation\(log.violationsFound == 1 ? "" : "s")")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                } else {
                    Text("Clean")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }
            Text("\(log.messagesScanned) messages scanned · \(log.remediatedCount) remediated")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
