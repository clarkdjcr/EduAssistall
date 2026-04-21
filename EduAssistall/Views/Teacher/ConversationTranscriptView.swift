import SwiftUI
import FirebaseFirestore

/// Read-only real-time view of a student's companion conversation (FR-200).
/// Teachers can also inject a hint into the student's next AI response (FR-204).
struct ConversationTranscriptView: View {
    let studentId: String
    let studentEmail: String
    var teacherProfile: UserProfile? = nil

    @State private var messages: [ChatMessage] = []
    @State private var listener: ListenerRegistration?

    // FR-204: hint injection
    @State private var showHintSheet = false
    @State private var hintText = ""
    @State private var isSendingHint = false
    @State private var hintSentConfirmation = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if messages.isEmpty {
                        Text("No messages yet in this session.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else {
                        ForEach(messages) { message in
                            TranscriptBubble(message: message)
                                .id(message.id)
                        }
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("\(studentEmail) — Live")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // FR-204: hint injection button (only when teacher profile available)
                    if teacherProfile != nil {
                        Button {
                            showHintSheet = true
                        } label: {
                            Label("Send Hint", systemImage: "lightbulb.fill")
                                .foregroundStyle(.indigo)
                        }
                    }
                    Label("Read Only", systemImage: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showHintSheet) {
            hintSheet
        }
        .onAppear {
            listener = FirestoreService.shared.listenConversationMessages(studentId: studentId) { msgs in
                messages = msgs
            }
        }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Hint Sheet (FR-204)

    private var hintSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("The student will see a banner saying their teacher sent a hint, but won't see the hint text. The AI will naturally weave it into its next response.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("e.g. Remind them to check units of measurement", text: $hintText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if hintSentConfirmation {
                    Label("Hint sent!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.bold())
                }

                Spacer()
            }
            .padding(20)
            .background(Color.appGroupedBackground)
            .navigationTitle("Send Hint to \(studentEmail)")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        hintText = ""
                        hintSentConfirmation = false
                        showHintSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSendingHint ? "Sending…" : "Send") {
                        Task { await sendHint() }
                    }
                    .disabled(hintText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingHint)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sendHint() async {
        guard let teacher = teacherProfile else { return }
        let text = hintText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isSendingHint = true
        try? await FirestoreService.shared.sendTeacherHint(studentId: studentId, text: text, teacher: teacher)
        isSendingHint = false
        hintSentConfirmation = true
        hintText = ""
        try? await Task.sleep(for: .seconds(1.5))
        showHintSheet = false
        hintSentConfirmation = false
    }
}

// MARK: - Transcript Bubble

private struct TranscriptBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                Text(isUser ? "Student" : "AI Companion")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(isUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isUser ? Color.blue : Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
