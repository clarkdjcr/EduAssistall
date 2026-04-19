import SwiftUI

extension Color {
    /// Primary background (white / near-white)
    static var appBackground: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }

    /// Secondary background (light gray cards / input fields)
    static var appSecondaryBackground: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.secondarySystemBackground)
        #endif
    }

    /// Grouped list background
    static var appGroupedBackground: Color {
        #if os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color(UIColor.systemGroupedBackground)
        #endif
    }

    /// Secondary grouped list background (card surfaces inside grouped lists)
    static var appSecondaryGroupedBackground: Color {
        #if os(macOS)
        Color(NSColor.textBackgroundColor)
        #else
        Color(UIColor.secondarySystemGroupedBackground)
        #endif
    }
}
