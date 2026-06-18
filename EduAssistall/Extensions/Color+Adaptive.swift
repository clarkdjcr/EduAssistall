import SwiftUI

// Centralized adaptive background colors. UIKit's system background colors
// (and their grouped variants) are iOS/visionOS-only, so we map to AppKit's
// nearest equivalents on macOS. Keep all platform conditionals here — never
// inline `#if os(iOS)` in views (see CLAUDE.md).
extension Color {

    /// Primary window/content background.
    static var appBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    /// Secondary background layered on top of `appBackground`.
    static var appSecondaryBackground: Color {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    /// Background for grouped content (e.g. the base behind grouped lists).
    static var appGroupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }

    /// Secondary grouped background for cards/rows within grouped content.
    static var appSecondaryGroupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
}
