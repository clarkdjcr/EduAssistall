import SwiftUI

struct DataRetentionView: View {
    let profile: UserProfile

    @State private var config = DataRetentionConfig()
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showConfirmation = false

    var body: some View {
        List {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Section {
                    RetentionRow(
                        label: "Conversation Messages",
                        icon: "bubble.left.and.bubble.right",
                        days: $config.conversationRetentionDays,
                        range: 30...365
                    )
                    RetentionRow(
                        label: "Session Flags",
                        icon: "flag",
                        days: $config.sessionFlagRetentionDays,
                        range: 7...90
                    )
                    RetentionRow(
                        label: "Safety Classifications",
                        icon: "shield",
                        days: $config.classificationRetentionDays,
                        range: 30...365
                    )
                    RetentionRow(
                        label: "Audit Logs",
                        icon: "doc.text",
                        days: $config.auditLogRetentionDays,
                        range: 180...730
                    )
                } header: {
                    Text("Retention Periods")
                } footer: {
                    Text("Data older than these thresholds is automatically deleted each night at 03:00 UTC. Critical safety events are kept permanently regardless of this setting.")
                }

                Section {
                    Button {
                        showConfirmation = true
                    } label: {
                        Label("Save Changes", systemImage: "checkmark.circle")
                            .foregroundStyle(isSaving ? Color.secondary : Color.blue)
                    }
                    .disabled(isSaving)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
        .navigationTitle("Data Retention")
        .inlineNavigationTitle()
        .task { await load() }
        .confirmationDialog(
            "Save Retention Config?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Save", role: .destructive) { Task { await save() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update the auto-purge schedule for all users in the system.")
        }
    }

    private func load() async {
        isLoading = true
        config = (try? await FirestoreService.shared.fetchDataRetentionConfig()) ?? DataRetentionConfig()
        isLoading = false
    }

    private func save() async {
        isSaving = true
        try? await FirestoreService.shared.saveDataRetentionConfig(config, updatedBy: profile.id)
        isSaving = false
    }
}

private struct RetentionRow: View {
    let label: String
    let icon: String
    @Binding var days: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.subheadline)
                Spacer()
                Text("\(days) days")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .monospacedDigit()
            }
            Slider(
                value: Binding(
                    get: { Double(days) },
                    set: { days = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(.blue)
            HStack {
                Text("\(range.lowerBound)d")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(range.upperBound)d")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
