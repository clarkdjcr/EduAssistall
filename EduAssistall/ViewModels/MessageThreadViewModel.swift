import Foundation

struct MessagePendingAttachment: Identifiable {
    let id = UUID()
    let filename: String
    let data: Data
    let mimeType: String
}

@Observable
final class MessageThreadViewModel {
    var messages: [Message] = []
    var isLoading = false
    var isSending = false

    func loadMessages(threadId: String) async {
        isLoading = true
        messages = (try? await FirestoreService.shared.fetchMessages(threadId: threadId)) ?? []
        isLoading = false
    }

    func send(
        thread: MessageThread,
        currentUser: UserProfile,
        body: String,
        pendingAttachments: [MessagePendingAttachment]
    ) async {
        isSending = true

        var uploaded: [MessageAttachment] = []
        for att in pendingAttachments {
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
