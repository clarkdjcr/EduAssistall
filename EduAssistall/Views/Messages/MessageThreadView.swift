import SwiftUI

struct MessageThreadView: View {
    let thread: MessageThread
    let currentUser: UserProfile

    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var draftText = ""
    @State private var pendingAttachments: [PendingAttachment] = []
    @State private var isSending = false

    #if os(iOS)
    @State private var showImagePicker = false
    #endif

    struct PendingAttachment: Identifiable {
        let id = UUID()
        let filename: String
        let data: Data
        let mimeType: String
    }

    private var canSend: Bool {
        let hasText = !draftText.trimmingCharacters(in: .whitespaces).isEmpty
        return (hasText || !pendingAttachments.isEmpty) && !isSending
    }

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

            if !pendingAttachments.isEmpty {
                pendingAttachmentBar
            }

            messageInput
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(thread.otherParticipantName(currentUserId: currentUser.id))
        .inlineNavigationTitle()
        .task { await load() }
        #if os(iOS)
        .sheet(isPresented: $showImagePicker) {
            ImageAttachmentPicker { data, filename, mime in
                pendingAttachments.append(PendingAttachment(filename: filename, data: data, mimeType: mime))
            }
        }
        #endif
    }

    // MARK: - Pending attachment bar

    private var pendingAttachmentBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(pendingAttachments) { att in
                    HStack(spacing: 6) {
                        Image(systemName: att.mimeType.hasPrefix("image/") ? "photo.fill" : "doc.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(att.filename)
                            .font(.caption)
                            .lineLimit(1)
                        Button {
                            pendingAttachments.removeAll { $0.id == att.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.appGroupedBackground)
    }

    // MARK: - Message input bar

    private var messageInput: some View {
        HStack(spacing: 10) {
            #if os(iOS)
            Button {
                showImagePicker = true
            } label: {
                Image(systemName: "paperclip")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            #endif

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
                    .foregroundStyle(canSend ? Color.blue : Color.secondary)
            }
            .disabled(!canSend)
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
        isSending = true
        draftText = ""
        let captured = pendingAttachments
        pendingAttachments = []

        var uploaded: [MessageAttachment] = []
        for att in captured {
            if let (ref, url) = try? await StorageService.shared.upload(
                data: att.data,
                path: StorageService.submissionPath(
                    studentId: currentUser.id,
                    threadId: thread.id,
                    filename: "\(UUID().uuidString)_\(att.filename)"
                ),
                mimeType: att.mimeType
            ) {
                uploaded.append(MessageAttachment(
                    filename: att.filename, storageRef: ref,
                    downloadURL: url, mimeType: att.mimeType, sizeBytes: att.data.count
                ))
            }
        }

        let message = Message(
            threadId: thread.id,
            senderId: currentUser.id,
            senderName: currentUser.displayName,
            body: body.isEmpty ? "(Attachment)" : body,
            attachments: uploaded
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

                if !message.attachments.isEmpty {
                    ForEach(message.attachments) { att in
                        AttachmentChip(attachment: att, outgoing: isFromCurrentUser)
                    }
                }

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

// MARK: - Attachment Chip

private struct AttachmentChip: View {
    let attachment: MessageAttachment
    let outgoing: Bool

    var body: some View {
        if let url = URL(string: attachment.downloadURL) {
            Link(destination: url) {
                HStack(spacing: 6) {
                    Image(systemName: attachment.typeIcon)
                        .font(.caption)
                    Text(attachment.filename)
                        .font(.caption)
                        .lineLimit(1)
                    Text(attachment.sizeLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(outgoing ? Color.white.opacity(0.2) : Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .foregroundStyle(outgoing ? Color.white : Color.blue)
            }
        }
    }
}
