import SwiftUI

struct MessageThreadView: View {
    let thread: MessageThread
    let currentUser: UserProfile

    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var draftText = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == currentUser.id
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }

            Divider()
            messageInput
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(thread.otherParticipantName(currentUserId: currentUser.id))
        .inlineNavigationTitle()
        .task { await load() }
    }

    private var messageInput: some View {
        HStack(spacing: 10) {
            TextField("Message…", text: $draftText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(draftText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.blue)
            }
            .disabled(draftText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appGroupedBackground)
    }

    private func load() async {
        isLoading = true
        messages = (try? await FirestoreService.shared.fetchMessages(threadId: thread.id)) ?? []
        isLoading = false
    }

    private func send() async {
        let body = draftText.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return }
        isSending = true
        draftText = ""
        let message = Message(
            threadId: thread.id,
            senderId: currentUser.id,
            senderName: currentUser.displayName,
            body: body
        )
        try? await FirestoreService.shared.sendMessage(message)
        messages.append(message)
        isSending = false
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 60) }
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                Text(message.body)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(isFromCurrentUser ? Color.blue : Color.appSecondaryGroupedBackground)
                    .foregroundStyle(isFromCurrentUser ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                if message.aiDrafted {
                    Label("AI assisted", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}
