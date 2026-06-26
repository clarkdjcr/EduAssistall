import SwiftUI

struct MessageThreadView: View {
    let thread: MessageThread
    let currentUser: UserProfile

    @State private var vm = MessageThreadViewModel()
    @State private var draftText = ""
    @State private var pendingAttachments: [MessagePendingAttachment] = []

    #if os(iOS)
    @State private var showImagePicker = false
    #endif

    private var canSend: Bool {
        let hasText = !draftText.trimmingCharacters(in: .whitespaces).isEmpty
        return (hasText || !pendingAttachments.isEmpty) && !vm.isSending
    }

    var body: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                SkeletonBubblesView()
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                messageList
            }

            if let error = vm.sendError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Dismiss") { withAnimation { vm.sendError = nil } }
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.08))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Divider()

            if !pendingAttachments.isEmpty {
                pendingAttachmentBar
            }

            messageInputBar
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(thread.otherParticipantName(currentUserId: currentUser.id))
        .inlineNavigationTitle()
        .animation(.easeInOut(duration: 0.25), value: vm.sendError)
        .onAppear { vm.startListening(threadId: thread.id) }
        .onDisappear { vm.stopListening() }
        #if os(iOS)
        .sheet(isPresented: $showImagePicker) {
            ImageAttachmentPicker { data, filename, mime in
                pendingAttachments.append(MessagePendingAttachment(filename: filename, data: data, mimeType: mime))
            }
        }
        #endif
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(vm.messages) { message in
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: message.senderId == currentUser.id
                        )
                        .id(message.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    if vm.isSending {
                        SendingBubble()
                            .id("sending")
                            .transition(.opacity)
                    }

                    Color.clear.frame(height: 4).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.messages.count)
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .onChange(of: vm.isSending) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }

    // MARK: - Pending Attachment Bar

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

    // MARK: - Input Bar

    private var messageInputBar: some View {
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
                .onSubmit {
                    guard canSend else { return }
                    let body = draftText.trimmingCharacters(in: .whitespaces)
                    let captured = pendingAttachments
                    draftText = ""
                    pendingAttachments = []
                    Task { await vm.send(thread: thread, currentUser: currentUser, body: body, pendingAttachments: captured) }
                }

            Button {
                let body = draftText.trimmingCharacters(in: .whitespaces)
                let captured = pendingAttachments
                draftText = ""
                pendingAttachments = []
                Task { await vm.send(thread: thread, currentUser: currentUser, body: body, pendingAttachments: captured) }
            } label: {
                if vm.isSending {
                    ProgressView()
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(canSend ? Color.blue : Color.secondary)
                }
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appGroupedBackground)
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    @State private var showTimestamp = false

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

                if showTimestamp {
                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) { showTimestamp.toggle() }
        }
    }
}

// MARK: - Sending Bubble

private struct SendingBubble: View {
    @State private var pulsing = false

    var body: some View {
        HStack {
            Spacer(minLength: 60)
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.blue.opacity(0.4))
                .frame(width: 80, height: 36)
                .overlay(
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.7)
                )
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
