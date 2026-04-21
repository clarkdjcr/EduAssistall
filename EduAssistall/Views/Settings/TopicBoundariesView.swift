import SwiftUI

/// Admin/teacher view for configuring per-grade-band topic boundaries (FR-105).
/// Changes saved here propagate to active sessions within one request cycle (<60 s).
struct TopicBoundariesView: View {
    let districtId: String

    @State private var config: DistrictConfig?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var saveSuccess = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading district config…")
            } else if let config = Binding($config) {
                Form {
                    allBandsSection(config: config)
                    ForEach(GradeBand.allCases) { band in
                        gradeBandSection(band: band, config: config)
                    }
                    saveSection
                }
            }
        }
        .navigationTitle("Topic Boundaries")
        .inlineNavigationTitle()
        .task { await load() }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private func allBandsSection(config: Binding<DistrictConfig>) -> some View {
        Section {
            TopicListEditor(
                topics: config.blockedTopics,
                placeholder: "Add topic blocked for all grades…"
            )
        } header: {
            Text("All Grade Bands")
        } footer: {
            Text("These topics are blocked across every grade band in your district.")
                .font(.caption)
        }
    }

    private func gradeBandSection(band: GradeBand, config: Binding<DistrictConfig>) -> some View {
        let binding = Binding<[String]>(
            get: { config.wrappedValue.gradeBandTopics[band.rawValue] ?? [] },
            set: { config.wrappedValue.gradeBandTopics[band.rawValue] = $0 }
        )
        return Section {
            TopicListEditor(
                topics: binding,
                placeholder: "Add topic blocked for grades \(band.displayName)…"
            )
        } header: {
            Text("Grades \(band.displayName)")
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    HStack {
                        ProgressView().padding(.trailing, 4)
                        Text("Saving…")
                    }
                } else {
                    Label(saveSuccess ? "Saved" : "Save Changes", systemImage: saveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down")
                }
            }
            .disabled(isSaving || config == nil)
            .foregroundStyle(saveSuccess ? .green : .accentColor)
        } footer: {
            Text("Changes take effect for new companion sessions within 60 seconds.")
                .font(.caption)
        }
    }

    // MARK: - Data

    private func load() async {
        isLoading = true
        do {
            config = try await FirestoreService.shared.fetchDistrictConfig(districtId: districtId)
                ?? DistrictConfig(id: districtId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        guard let cfg = config else { return }
        isSaving = true
        saveSuccess = false
        do {
            try await FirestoreService.shared.saveDistrictConfig(cfg)
            saveSuccess = true
            // Reset success indicator after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            saveSuccess = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Topic List Editor

/// Reusable row-based topic list with inline add and swipe-to-delete.
private struct TopicListEditor: View {
    @Binding var topics: [String]
    let placeholder: String

    @State private var newTopic = ""

    var body: some View {
        ForEach(topics, id: \.self) { topic in
            HStack {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
                    .onTapGesture { remove(topic) }
                Text(topic)
            }
        }
        .onDelete { offsets in
            topics.remove(atOffsets: offsets)
        }

        HStack {
            TextField(placeholder, text: $newTopic)
                .submitLabel(.done)
                .onSubmit { addTopic() }
            Button(action: addTopic) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.tint)
            }
            .disabled(newTopic.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addTopic() {
        let trimmed = newTopic.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !topics.contains(trimmed) else { return }
        topics.append(trimmed)
        newTopic = ""
    }

    private func remove(_ topic: String) {
        topics.removeAll { $0 == topic }
    }
}
