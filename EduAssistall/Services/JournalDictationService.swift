import Foundation
import Speech
#if os(iOS)
import AVFoundation
#endif

/// On-device speech-to-text for the private teacher journal. Audio and transcript never leave
/// the device. Uses the `SpeechTranscriber` / `SpeechAnalyzer` live-capture pipeline on iOS 27+
/// (the `AnalyzerInputConverter` capture helper requires iOS 27), and falls back to the iOS 17
/// `SFSpeechRecognizer` with on-device recognition forced on for iOS 17–26.
///
/// Voice journaling is iOS/iPadOS only (it needs `AVAudioSession`); on other platforms or when
/// permissions are denied, `isAvailable` is false and the journal stays typed-only.
@MainActor
@Observable
final class JournalDictationService {

    /// Live transcript, updated as the teacher speaks.
    private(set) var transcript: String = ""
    private(set) var isRecording = false
    private(set) var errorMessage: String?

    /// True only on iOS/iPadOS, where microphone capture + on-device speech are supported.
    static var isSupported: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    #if os(iOS)
    private let audioEngine = AVAudioEngine()

    // iOS 26+ pipeline state.
    private var analyzer: Any?
    private var inputBuilder: Any?
    private var recognizerTask: Task<Void, Never>?

    // iOS 17–25 fallback state.
    private var legacyRequest: SFSpeechAudioBufferRecognitionRequest?
    private var legacyTask: SFSpeechRecognitionTask?

    func start() async {
        guard !isRecording else { return }
        errorMessage = nil
        transcript = ""

        guard await requestPermissions() else {
            errorMessage = "Microphone and speech permission are required for voice journaling."
            return
        }

        do {
            if #available(iOS 27, *) {
                try await startModern()
            } else {
                try startLegacy()
            }
            isRecording = true
        } catch {
            errorMessage = "Couldn't start dictation: \(error.localizedDescription)"
            await stop()
        }
    }

    func stop() async {
        guard isRecording || audioEngine.isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning { audioEngine.stop() }

        if #available(iOS 27, *) {
            await finishModern()
        } else {
            legacyRequest?.endAudio()
            legacyTask?.finish()
            legacyRequest = nil
            legacyTask = nil
        }
        isRecording = false
    }

    // MARK: - iOS 27+ : SpeechTranscriber / SpeechAnalyzer (live mic capture)

    @available(iOS 27, *)
    private func startModern() async throws {
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
            throw DictationError.localeUnsupported
        }
        let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)

        // Ensure on-device model assets are present (downloads on first use).
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }

        let (inputSequence, builder) = AsyncStream.makeStream(of: AnalyzerInput.self)
        self.inputBuilder = builder

        guard let audioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw DictationError.recognizerUnavailable
        }
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        // Consume results on the main actor.
        recognizerTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    await MainActor.run { self?.transcript = text }
                }
            } catch {
                await MainActor.run { self?.errorMessage = error.localizedDescription }
            }
        }

        // Capture microphone audio and feed converted buffers into the analyzer.
        try configureAudioSession()
        let converter = AnalyzerInputConverter(analyzerFormat: audioFormat)
        let inputNode = audioEngine.inputNode
        let tapFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: tapFormat) { buffer, _ in
            if let inputs = try? converter.convert(buffer, at: nil) {
                for input in inputs { builder.yield(input) }
            }
        }
        audioEngine.prepare()
        try audioEngine.start()
        try await analyzer.start(inputSequence: inputSequence)
    }

    @available(iOS 27, *)
    private func finishModern() async {
        (inputBuilder as? AsyncStream<AnalyzerInput>.Continuation)?.finish()
        if let analyzer = analyzer as? SpeechAnalyzer {
            await analyzer.cancelAndFinishNow()
        }
        recognizerTask?.cancel()
        recognizerTask = nil
        analyzer = nil
        inputBuilder = nil
    }

    // MARK: - iOS 17–26 : SFSpeechRecognizer fallback (on-device)

    private func startLegacy() throws {
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current), recognizer.isAvailable else {
            throw DictationError.recognizerUnavailable
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true   // keep audio on-device
        legacyRequest = request

        try configureAudioSession()
        let inputNode = audioEngine.inputNode
        let tapFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: tapFormat) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        legacyTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in self.transcript = result.bestTranscription.formattedString }
            }
            if error != nil {
                Task { @MainActor in await self.stop() }
            }
        }
    }

    // MARK: - Audio session + permissions

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func requestPermissions() async -> Bool {
        let speechOK = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard speechOK else { return false }

        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    enum DictationError: LocalizedError {
        case localeUnsupported
        case recognizerUnavailable

        var errorDescription: String? {
            switch self {
            case .localeUnsupported:   return "Your language isn't supported for on-device dictation."
            case .recognizerUnavailable: return "On-device speech recognition isn't available on this device."
            }
        }
    }
    #else
    // Non-iOS: voice journaling unavailable; typed entry only.
    func start() async { errorMessage = "Voice journaling is available on iPad and iPhone." }
    func stop() async {}
    #endif
}
