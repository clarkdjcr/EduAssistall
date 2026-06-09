import SwiftUI

/// Reusable on-device dictation control. Place it beneath any text field and bind its text;
/// tapping the mic starts/stops transcription and the live transcript is appended to the bound
/// text. Audio and transcript stay on the device. Renders nothing where speech isn't supported.
struct DictationControl: View {
    @Binding var text: String
    /// Called once when recording starts (e.g. to mark an entry's source as voice).
    var onActivate: (() -> Void)? = nil

    @State private var dictation = JournalDictationService()
    @State private var preText = ""

    var body: some View {
        if JournalDictationService.isSupported {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Button(action: toggle) {
                        Image(systemName: dictation.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(dictation.isRecording ? .red : Color.accentColor)
                            .symbolEffect(.pulse, isActive: dictation.isRecording)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(dictation.isRecording ? "Stop dictation" : "Start dictation")

                    Text(dictation.isRecording ? "Listening… tap to stop" : "Dictate (on device)")
                        .font(.caption)
                        .foregroundStyle(dictation.isRecording ? .red : .secondary)
                    Spacer()
                }

                if let err = dictation.errorMessage {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onChange(of: dictation.transcript) { _, newValue in
                guard dictation.isRecording else { return }
                text = preText.isEmpty ? newValue : preText + " " + newValue
            }
            .onDisappear {
                Task { await dictation.stop() }
            }
        }
    }

    private func toggle() {
        if dictation.isRecording {
            Task { await dictation.stop() }
        } else {
            preText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            onActivate?()
            Task { await dictation.start() }
        }
    }
}
