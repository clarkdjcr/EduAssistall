import SwiftUI
import FirebaseFirestore
#if canImport(ImagePlayground)
import ImagePlayground
#endif

struct CompanionView: View {
    let profile: UserProfile

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    // FR-106: real-time lock state — listener fires within ~1 s of educator activation
    @State private var isLocked = false
    @State private var lockListener: ListenerRegistration?

    // FR-204: pending teacher hint
    @State private var pendingHint: TeacherHint?
    @State private var hintListener: ListenerRegistration?

    // FR-003: Interaction mode
    @State private var currentMode: InteractionMode = .guidedDiscovery
    @State private var allowedModes: [InteractionMode] = InteractionMode.allCases
    @State private var showModePicker = false

    // Context-aware suggestion chips
    @State private var activePath: LearningPath?

    // Grade level loaded from LearningProfile for on-device model context
    @State private var gradeLevel: String?

    // Apple Intelligence — on-device draft shown while cloud call is in flight
    @State private var draftReply: String?
    // Image Playground (2D)
    @State private var showImagePlayground = false
    @State private var imageConceptText = ""
    @State private var generatedImageURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLocked {
                    lockedBanner
                }
                if pendingHint != nil {
                    hintBanner
                }
                if !ConnectivityService.shared.isOnline {
                    offlineBanner
                }
                messageList
                Divider()
                inputBar
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("AI Companion")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showModePicker = true
                    } label: {
                        Label(currentMode.displayName, systemImage: "dial.medium")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showModePicker) {
                ModePickerSheet(
                    currentMode: $currentMode,
                    allowedModes: allowedModes,
                    studentId: profile.id
                )
                .presentationDetents([.medium])
            }
            .task {
                await loadHistory()
                await loadModeFromProfile()
                await loadActivePath()
            }
            .onAppear {
                startLockListener()
                hintListener = FirestoreService.shared.listenPendingHint(studentId: profile.id) { hint in
                    withAnimation { pendingHint = hint }
                }
                // FR-200: Mark session active so educators see it within <5 s.
                FirestoreService.shared.setActiveSession(
                    studentId: profile.id,
                    studentEmail: profile.email,
                    isActive: true
                )
            }
            .onDisappear {
                lockListener?.remove()
                hintListener?.remove()
                FirestoreService.shared.setActiveSession(
                    studentId: profile.id,
                    studentEmail: profile.email,
                    isActive: false
                )
                // FR-302: Generate journal entry if the session had at least 4 messages (2 exchanges).
                if messages.count >= 4 {
                    CloudFunctionService.shared.generateJournalEntry(
                        studentId: profile.id,
                        conversationId: profile.id
                    )
                }
            }
        }
    }

    // MARK: - Lock Banner (FR-106)

    private var lockedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
            Text("Your companion session has been paused by your educator.")
                .font(.caption.bold())
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange)
    }

    // MARK: - Offline Banner

    private var offlineBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
            Text("You're offline. Messages will fail until your connection is restored.")
                .font(.caption.bold())
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.gray)
    }

    // MARK: - Hint Banner (FR-204)

    private var hintBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
            Text("Your teacher has sent you a hint — it will guide my next response.")
                .font(.caption.bold())
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.indigo)
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else if messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }

                    if isThinking {
                        if let draft = draftReply {
                            // 2C: Show on-device draft while cloud reply is in flight.
                            ChatBubbleView(message: ChatMessage(role: .assistant, text: draft))
                                .id("draft")
                                .opacity(0.7)
                                .transition(.opacity)
                        } else {
                            TypingIndicatorView()
                                .id("typing")
                                .transition(.opacity)
                        }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                            .id("error")
                    }

                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: isThinking) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask anything...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityLabel("Message input")
                .accessibilityHint("Type your question or message to the AI companion")

            // 2D: Image Playground — generate educational diagrams on-device (iOS 18.1+)
            #if canImport(ImagePlayground)
            if #available(iOS 18.1, *) {
                Button {
                    imageConceptText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    showImagePlayground = true
                } label: {
                    Image(systemName: "wand.and.sparkles")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.purple.opacity(0.8))
                }
                .accessibilityLabel("Generate visual")
                .accessibilityHint("Create an on-device educational diagram for your topic")
            }
            #endif

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Color.blue : Color.secondary)
            }
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: .command)
            .accessibilityLabel("Send message")
            .accessibilityHint(canSend ? "Sends your message to the AI companion" : "Type a message first")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appGroupedBackground)
        #if canImport(ImagePlayground)
        .imagePlaygroundSheet(
            isPresented: $showImagePlayground,
            concept: imageConceptText
        ) { url in
            generatedImageURL = url
            // Append a message so the student can see the diagram inline.
            messages.append(ChatMessage(
                role: .assistant,
                text: "Here's a visual for \"\(imageConceptText)\": \(url.absoluteString)"
            ))
        } onCancellation: {
            showImagePlayground = false
        }
        #endif
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue.opacity(0.6))
            Text("Your AI Companion")
                .font(.title3.bold())
            Text("Ask me anything about your lessons, homework, or topics you're curious about!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 10) {
                if let path = activePath {
                    SuggestionChip(text: "Help me with \(path.title)") {
                        inputText = "Help me with \(path.title)"
                    }
                    SuggestionChip(text: "Quiz me on \(path.title)") {
                        inputText = "Quiz me on \(path.title)"
                    }
                } else {
                    SuggestionChip(text: "Help me understand fractions") {
                        inputText = "Help me understand fractions"
                    }
                    SuggestionChip(text: "What is photosynthesis?") {
                        inputText = "What is photosynthesis?"
                    }
                }
                SuggestionChip(text: "Can you quiz me on my current lesson?") {
                    inputText = "Can you quiz me on my current lesson?"
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isThinking && !isLocked
    }

    private func loadModeFromProfile() async {
        guard let lp = try? await FirestoreService.shared.fetchLearningProfile(studentId: profile.id) else { return }
        allowedModes = lp.allowedInteractionModes.isEmpty ? InteractionMode.allCases : lp.allowedInteractionModes
        currentMode = allowedModes.contains(lp.currentInteractionMode) ? lp.currentInteractionMode : (allowedModes.first ?? .guidedDiscovery)
        gradeLevel = lp.grade.isEmpty ? nil : lp.grade
    }

    private func startLockListener() {
        lockListener = FirestoreService.shared.listenCompanionLock(studentId: profile.id) { locked in
            withAnimation { isLocked = locked }
        }
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        errorMessage = nil
        draftReply = nil
        withAnimation { pendingHint = nil }

        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        isThinking = true

        // 2A: Classify intent on-device before touching the network.
        let intent = await IntentClassifierService.shared.classify(text)

        // Safety concerns always go to the cloud safety pipeline — never answered on-device.
        // Educational and simpleFactual both go to cloud; simpleFactual could be answered on-device
        // in a future iteration but we still want the safety + logging pipeline for now.
        // The main win here is that future simple-factual answers can bypass cloud entirely
        // once we validate quality. For now the classification is used for telemetry.
        _ = intent  // reserved for future on-device answer path

        // 2B: Compress history before the cloud call to reduce input tokens.
        let compressed = await LocalDraftService.shared.compressHistory(
            messages.dropLast().map { $0 },  // exclude the message we just appended
            gradeLevel: gradeLevel
        )

        // 2C: Start on-device draft in parallel with the cloud call.
        // If the draft arrives before the cloud reply, show it immediately.
        Task { @MainActor in
            if let draft = await LocalDraftService.shared.generateDraft(
                for: text,
                context: compressed,
                gradeLevel: gradeLevel
            ), isThinking {
                draftReply = draft
            }
        }

        do {
            let reply = try await CloudFunctionService.shared.askCompanion(
                message: text,
                studentId: profile.id,
                mode: currentMode,
                compressedHistory: compressed
            )
            draftReply = nil
            messages.append(ChatMessage(role: .assistant, text: reply))
        } catch let ce as CompanionError {
            draftReply = nil
            messages.removeLast() // remove the optimistically-added user bubble on failure
            inputText = ce.isRetryable ? text : ""
            errorMessage = ce.errorDescription
        } catch {
            draftReply = nil
            messages.removeLast()
            inputText = text
            errorMessage = "Something went wrong. Please try again."
        }

        isThinking = false
    }

    private func loadHistory() async {
        isLoading = true
        messages = (try? await FirestoreService.shared.fetchRecentConversationMessages(
            studentId: profile.id, limit: 20
        )) ?? []
        isLoading = false
    }

    private func loadActivePath() async {
        activePath = try? await FirestoreService.shared.fetchLearningPaths(studentId: profile.id).first
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    private var assistantAttributed: AttributedString {
        (try? AttributedString(
            markdown: message.text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )) ?? AttributedString(message.text)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }

            if !isUser {
                Image(systemName: "brain.filled.head.profile")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }

            Group {
                if isUser {
                    Text(message.text)
                } else {
                    Text(assistantAttributed)
                }
            }
            .font(.body)
            .foregroundStyle(isUser ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isUser ? Color.blue : Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if isUser {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }

            if !isUser { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "brain.filled.head.profile")
                .font(.caption)
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(i) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer(minLength: 48)
        }
        .onAppear { animating = true }
    }
}

// MARK: - Suggestion Chip

private struct SuggestionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Picker Sheet (FR-003)

private struct ModePickerSheet: View {
    @Binding var currentMode: InteractionMode
    let allowedModes: [InteractionMode]
    let studentId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(allowedModes) { mode in
                Button {
                    currentMode = mode
                    Task {
                        try? await FirestoreService.shared.setInteractionMode(
                            mode, for: studentId, allowed: allowedModes
                        )
                    }
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: iconName(for: mode))
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if mode == currentMode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .navigationTitle("Learning Mode")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func iconName(for mode: InteractionMode) -> String {
        switch mode {
        case .guidedDiscovery:    return "magnifyingglass"
        case .coCreation:         return "person.2.fill"
        case .reflectiveCoaching: return "brain.head.profile"
        case .silentSupport:      return "ear"
        }
    }
}
