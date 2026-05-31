import SwiftUI

var adaptiveTopBarLeading: ToolbarItemPlacement {
    #if os(macOS)
    .cancellationAction
    #else
    .topBarLeading
    #endif
}

var adaptiveTopBarTrailing: ToolbarItemPlacement {
    #if os(macOS)
    .confirmationAction
    #else
    .topBarTrailing
    #endif
}

extension View {
    /// Email address keyboard + autocomplete hints — iOS/visionOS only.
    func emailInput() -> some View {
        self
            .autocorrectionDisabled()
        #if os(iOS)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
        #endif
    }

    /// New password content hint — iOS/visionOS only.
    func newPasswordInput() -> some View {
        #if os(iOS)
        self.textContentType(.newPassword)
        #else
        self
        #endif
    }

    /// Existing password content hint — iOS/visionOS only.
    func passwordInput() -> some View {
        #if os(iOS)
        self.textContentType(.password)
        #else
        self
        #endif
    }

    /// Name content hint — iOS/visionOS only.
    func nameInput() -> some View {
        #if os(iOS)
        self.textContentType(.name)
        #else
        self
        #endif
    }

    /// Inline navigation title display — iOS/visionOS only (no-op on macOS).
    func inlineNavigationTitle() -> some View {
        #if os(iOS) || os(visionOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// URL / domain input — disables autocorrect and autocapitalization cross-platform.
    func urlInput() -> some View {
        self
            .autocorrectionDisabled()
        #if os(iOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
        #endif
    }

    /// Numeric and punctuation keyboard — iOS/visionOS only.
    func numberInput() -> some View {
        #if os(iOS) || os(visionOS)
        self.keyboardType(.numbersAndPunctuation)
        #else
        self
        #endif
    }

    /// Hide the back button — iOS/visionOS only (no-op on macOS).
    func hideBackButton() -> some View {
        #if os(iOS) || os(visionOS)
        self.navigationBarBackButtonHidden(true)
        #else
        self
        #endif
    }

    /// Apply a transform closure, useful for conditional modifiers that can't use an if/else.
    @ViewBuilder
    func modify<T: View>(@ViewBuilder transform: (Self) -> T) -> T {
        transform(self)
    }

    /// Cross-platform picker style - wheel on iOS/visionOS, menu on macOS.
    func adaptivePickerStyle() -> some View {
        #if os(iOS) || os(visionOS)
        self.pickerStyle(.wheel)
        #else
        self.pickerStyle(.menu)
        #endif
    }

    /// Page TabView style for onboarding pages - page on iOS/visionOS, automatic on macOS.
    func welcomeTabViewStyle() -> some View {
        #if os(iOS) || os(visionOS)
        self.tabViewStyle(.page(indexDisplayMode: .never))
        #else
        self.tabViewStyle(.automatic)
        #endif
    }

    /// Cross-platform full screen cover / sheet fallback.
    func adaptiveFullScreenCover<Item, Content>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Item: Identifiable, Content: View {
        #if os(iOS) || os(visionOS)
        self.fullScreenCover(item: item, onDismiss: onDismiss, content: content)
        #else
        self.sheet(item: item, onDismiss: onDismiss, content: content)
        #endif
    }
}

/// Cross-platform clipboard write.
func copyToClipboard(_ text: String) {
    #if os(iOS) || os(visionOS)
    UIPasteboard.general.string = text
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #endif
}

/// Cross-platform ToolbarItemPlacement extensions.
extension ToolbarItemPlacement {
    static var adaptiveTrailing: ToolbarItemPlacement {
        #if os(iOS) || os(visionOS)
        return .topBarTrailing
        #else
        return .primaryAction
        #endif
    }
    
    static var adaptiveLeading: ToolbarItemPlacement {
        #if os(iOS) || os(visionOS)
        return .topBarLeading
        #else
        return .cancellationAction
        #endif
    }
}
