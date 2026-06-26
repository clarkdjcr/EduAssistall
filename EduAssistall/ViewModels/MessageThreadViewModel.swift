import Foundation
import SwiftUI
import FirebaseFirestore

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
    var sendError: String?

    private var listener: ListenerRegistration?

    func startListening(threadId: String) {
        isLoading = true
        listener = FirestoreService.shared.listenMessages(threadId: threadId) { [weak self] messages in
            self?.messages = messages
            self?.isLoading = false
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func send(
        thread: MessageThread,
        currentUser: UserProfile,
        body: String,
        pendingAttachments: [MessagePendingAttachment]
    ) async {
        isSending = true
        sendError = nil

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
        do {
            try await FirestoreService.shared.sendMessage(message)
            // Listener delivers the new message — no manual append needed
        } catch {
            withAnimation { sendError = "Message failed to send. Please try again." }
        }
        isSending = false
    }
}
