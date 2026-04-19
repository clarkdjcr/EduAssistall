import SwiftUI

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

    /// Hide the back button — iOS/visionOS only (no-op on macOS).
    func hideBackButton() -> some View {
        #if os(iOS) || os(visionOS)
        self.navigationBarBackButtonHidden(true)
        #else
        self
        #endif
    }
}
