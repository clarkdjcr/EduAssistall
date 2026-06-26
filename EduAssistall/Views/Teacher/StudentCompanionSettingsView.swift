import SwiftUI

struct StudentCompanionSettingsView: View {
    let studentId: String
    let studentName: String

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var defaultMode: InteractionMode = .guidedDiscovery
    @State private var allowedModes: Set<InteractionMode> = Set(InteractionMode.allCases)
    @State private var responseStyle: ResponseStyle = .standard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Form {
                        Section {
                            Picker("Default Mode", selection: $defaultMode) {
                                ForEach(InteractionMode.allCases) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .onChange(of: defaultMode) { _, new in
                                allowedModes.insert(new)
                            }
                        } header: {
                            Text("Default Interaction Mode")
                        } footer: {
                            Text(defaultMode.description)
                        }

                        Section {
                            ForEach(InteractionMode.allCases) { mode in
                                Toggle(isOn: Binding(
                                    get: { allowedModes.contains(mode) },
                                    set: { on in
                                        if on {
                                            allowedModes.insert(mode)
                                        } else if mode != defaultMode {
                                            allowedModes.remove(mode)
                                        }
                                    }
                                )) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mode.displayName).font(.subheadline)
                                        Text(mode.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("Allowed Modes")
                        } footer: {
                            Text("The student may only switch between modes listed here. The default mode is always included.")
                        }

                        Section {
                            Picker("Response Style", selection: $responseStyle) {
                                ForEach(ResponseStyle.allCases) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                        } header: {
                            Text("AI Response Style")
                        } footer: {
                            Text(responseStyle.description)
                        }

                        if let msg = errorMessage {
                            Section {
                                Label(msg, systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
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
            .navigationTitle("AI Companion — \(studentName)")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: adaptiveTopBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .fontWeight(.semibold)
                            .disabled(isLoading)
                    }
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        if let p = try? await FirestoreService.shared.fetchLearningProfile(studentId: studentId) {
            defaultMode  = p.defaultInteractionMode
            allowedModes = Set(p.allowedInteractionModes)
            responseStyle = p.responseStyle
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let allowed = Array(allowedModes)
        do {
            try await FirestoreService.shared.updateStudentCompanionConfig(
                studentId: studentId,
                defaultMode: defaultMode,
                allowedModes: allowed,
                responseStyle: responseStyle
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
