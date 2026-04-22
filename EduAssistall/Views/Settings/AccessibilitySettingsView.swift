import SwiftUI

/// NFR-005: WCAG 2.1 AA accessibility preferences — dyslexia-friendly font,
/// high-contrast mode, and large-text opt-in. Persisted via @AppStorage.
struct AccessibilitySettingsView: View {
    @AppStorage("a11y_dyslexiaFont")    private var dyslexiaFont: Bool    = false
    @AppStorage("a11y_highContrast")    private var highContrast: Bool    = false
    @AppStorage("a11y_largeText")       private var largeText: Bool       = false
    @AppStorage("a11y_reduceMotion")    private var reduceMotion: Bool    = false

    var body: some View {
        List {
            Section("Text & Reading") {
                Toggle(isOn: $dyslexiaFont) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dyslexia-Friendly Font")
                            .font(dyslexiaFont ? .body.monospaced() : .body)
                        Text("Uses a font with distinct letterforms to aid readability")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Dyslexia-friendly font")
                .accessibilityHint("Switches to a font designed to reduce letter confusion for readers with dyslexia")

                Toggle(isOn: $largeText) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Larger Text")
                        Text("Increases base font size across the app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Larger text")
                .accessibilityHint("Increases the default font size throughout the app")
            }

            Section("Display") {
                Toggle(isOn: $highContrast) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("High Contrast Mode")
                        Text("Increases colour contrast for text and interactive elements")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("High contrast mode")
                .accessibilityHint("Increases colour contrast to meet WCAG AA requirements")

                Toggle(isOn: $reduceMotion) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reduce Motion")
                        Text("Minimises animations and transitions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Reduce motion")
                .accessibilityHint("Minimises transitions and animations throughout the app")
            }

            Section("About") {
                LabeledContent("Accessibility Standard", value: "WCAG 2.1 AA")
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Accessibility standard: WCAG 2.1 level AA")
                LabeledContent("Keyboard Navigation", value: "Fully supported")
                    .accessibilityElement(children: .combine)
                Text("VoiceOver labels are provided for all interactive elements. Contact your administrator to report accessibility issues.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Accessibility")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Environment key for accessibility preferences

struct DyslexiaFontKey: EnvironmentKey {
    static let defaultValue = false
}
struct HighContrastKey: EnvironmentKey {
    static let defaultValue = false
}
struct LargeTextKey: EnvironmentKey {
    static let defaultValue = false
}
struct ReduceMotionPreferenceKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var dyslexiaFont: Bool {
        get { self[DyslexiaFontKey.self] }
        set { self[DyslexiaFontKey.self] = newValue }
    }
    var a11yHighContrast: Bool {
        get { self[HighContrastKey.self] }
        set { self[HighContrastKey.self] = newValue }
    }
    var a11yLargeText: Bool {
        get { self[LargeTextKey.self] }
        set { self[LargeTextKey.self] = newValue }
    }
    var a11yReduceMotion: Bool {
        get { self[ReduceMotionPreferenceKey.self] }
        set { self[ReduceMotionPreferenceKey.self] = newValue }
    }
}
