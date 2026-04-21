import SwiftUI

/// Educator view to set the default and allowed interaction modes for a single student (FR-003).
struct StudentModeConfigView: View {
    let studentId: String
    let studentEmail: String

    @State private var profile: LearningProfile?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                form
            }
        }
        .navigationTitle("Companion Modes")
        .inlineNavigationTitle()
        .task { await load() }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "") }
    }

    private var form: some View {
        Form {
            Section {
                Text("Configure which interaction modes \(studentEmail) can use.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Default Mode") {
                Picker("Default", selection: defaultModeBinding) {
                    ForEach(InteractionMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }

            Section {
                ForEach(InteractionMode.allCases) { mode in
                    Toggle(isOn: allowedBinding(for: mode)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName).font(.subheadline.bold())
                            Text(mode.description).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Allowed Modes")
            } footer: {
                Text("Students can only switch between modes you enable here.")
                    .font(.caption)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        HStack { ProgressView().padding(.trailing, 4); Text("Saving…") }
                    } else {
                        Label(saveSuccess ? "Saved" : "Save", systemImage: saveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down")
                    }
                }
                .disabled(isSaving || profile == nil)
                .foregroundStyle(saveSuccess ? .green : .accentColor)
            }
        }
    }

    // MARK: - Bindings

    private var defaultModeBinding: Binding<InteractionMode> {
        Binding(
            get: { profile?.defaultInteractionMode ?? .guidedDiscovery },
            set: { profile?.defaultInteractionMode = $0 }
        )
    }

    private func allowedBinding(for mode: InteractionMode) -> Binding<Bool> {
        Binding(
            get: { profile?.allowedInteractionModes.contains(mode) ?? true },
            set: { enabled in
                guard var p = profile else { return }
                if enabled {
                    if !p.allowedInteractionModes.contains(mode) {
                        p.allowedInteractionModes.append(mode)
                    }
                } else {
                    p.allowedInteractionModes.removeAll { $0 == mode }
                    // Ensure at least one mode is always allowed
                    if p.allowedInteractionModes.isEmpty {
                        p.allowedInteractionModes = [.guidedDiscovery]
                    }
                    // Reset default if it was just disabled
                    if !p.allowedInteractionModes.contains(p.defaultInteractionMode) {
                        p.defaultInteractionMode = p.allowedInteractionModes[0]
                    }
                }
                profile = p
            }
        )
    }

    // MARK: - Data

    private func load() async {
        isLoading = true
        profile = (try? await FirestoreService.shared.fetchLearningProfile(studentId: studentId))
            ?? LearningProfile(studentId: studentId)
        isLoading = false
    }

    private func save() async {
        guard let p = profile else { return }
        isSaving = true
        saveSuccess = false
        do {
            try await FirestoreService.shared.saveLearningProfile(p)
            saveSuccess = true
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            saveSuccess = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
