import SwiftUI

/// FR-203: Educator classroom configuration — sets class-wide defaults for interaction
/// modes, answer mode, and AI response style. Per-student overrides remain in StudentModeConfigView.
struct ClassroomConfigView: View {
    let teacherProfile: UserProfile

    @State private var config: ClassroomConfig?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var saveError: String?

    // Editable fields mirroring ClassroomConfig
    @State private var defaultMode: InteractionMode = .guidedDiscovery
    @State private var allowedModes: Set<InteractionMode> = Set(InteractionMode.allCases)
    @State private var answerModeDefault = false
    @State private var responseStyle: ResponseStyle = .standard

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                form
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Classroom Config")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || allowedModes.isEmpty)
            }
        }
        .task { await loadConfig() }
        .alert("Save Failed", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Form

    private var form: some View {
        List {
            // MARK: Interaction Mode
            Section {
                Picker("Default Mode", selection: $defaultMode) {
                    ForEach(InteractionMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .onChange(of: defaultMode) { _, newMode in
                    // Default mode must always be in the allowed set
                    allowedModes.insert(newMode)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Allowed Modes")
                        .font(.subheadline)
                    Text("Students can only switch between modes you enable here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(InteractionMode.allCases) { mode in
                        Toggle(isOn: Binding(
                            get: { allowedModes.contains(mode) },
                            set: { on in
                                if on { allowedModes.insert(mode) }
                                else if mode != defaultMode { allowedModes.remove(mode) }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName).font(.subheadline)
                                Text(mode.description).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .disabled(mode == defaultMode) // default must stay allowed
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Interaction Mode")
            } footer: {
                Text("The default mode is applied to new students. Students cannot switch to modes you have not enabled.")
            }

            // MARK: Answer Mode
            Section {
                Toggle("Answer Mode On by Default", isOn: $answerModeDefault)
            } header: {
                Text("Answer Mode")
            } footer: {
                Text("When enabled, new learning paths will allow the AI to give direct answers. You can override per-path in the learning path detail.")
            }

            // MARK: Response Style
            Section {
                ForEach(ResponseStyle.allCases) { style in
                    Button {
                        responseStyle = style
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: iconName(for: style))
                                .foregroundStyle(.blue)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.displayName)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if style == responseStyle {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("AI Response Style")
            } footer: {
                Text("Sets the tone of AI responses for all students in your class. Applied as the default when you onboard new students.")
            }

            // MARK: Apply to All Students
            Section {
                Button {
                    Task { await applyToAllStudents() }
                } label: {
                    Label("Apply Defaults to All Students", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.blue)
                }
            } footer: {
                Text("Overwrites each linked student's interaction mode and response style with the class defaults above. Per-student overrides will be reset.")
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    // MARK: - Helpers

    private func iconName(for style: ResponseStyle) -> String {
        switch style {
        case .standard:    return "text.bubble"
        case .encouraging: return "star.bubble"
        case .formal:      return "book.closed"
        }
    }

    private func loadConfig() async {
        isLoading = true
        let loaded = (try? await FirestoreService.shared.fetchClassroomConfig(teacherId: teacherProfile.id))
            ?? ClassroomConfig(teacherId: teacherProfile.id)
        config = loaded
        defaultMode = loaded.defaultInteractionMode
        allowedModes = Set(loaded.allowedInteractionModes)
        answerModeDefault = loaded.answerModeEnabledByDefault
        responseStyle = loaded.responseStyle
        isLoading = false
    }

    private func save() async {
        isSaving = true
        var updated = ClassroomConfig(teacherId: teacherProfile.id)
        updated.defaultInteractionMode = defaultMode
        updated.allowedInteractionModes = Array(allowedModes)
        updated.answerModeEnabledByDefault = answerModeDefault
        updated.responseStyle = responseStyle
        do {
            try await FirestoreService.shared.saveClassroomConfig(updated)
            config = updated
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }

    private func applyToAllStudents() async {
        guard let cfg = config else { return }
        isSaving = true
        let links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id)) ?? []
        await withTaskGroup(of: Void.self) { group in
            for link in links where link.confirmed {
                group.addTask {
                    try? await FirestoreService.shared.applyClassroomDefaults(config: cfg, to: link.studentId)
                }
            }
        }
        isSaving = false
    }
}
