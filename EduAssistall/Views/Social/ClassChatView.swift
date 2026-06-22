import SwiftUI

// Phase 3: Teacher-moderated class chat view
struct ClassChatView: View {
    let profile: UserProfile
    let classId: String
    
    @State private var messages: [ClassChatMessage] = []
    @State private var newMessage: String = ""
    @State private var isLoading = true
    @State private var isSending = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            if isLoading {
                ProgressView("Loading messages...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if messages.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.studentId == profile.id)
                        }
                    }
                    .padding()
                }
            }
            
            Divider()
            
            // Input bar
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isSending)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(newMessage.isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(newMessage.isEmpty || isSending)
            }
            .padding()
            .background(Color.appGroupedBackground)
        }
        .navigationTitle("Class Chat")
        .task {
            await loadMessages()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Messages Yet")
                .font(.headline)
            Text("Start a conversation with your classmates!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadMessages() async {
        isLoading = true
        messages = (try? await FirestoreService.shared.fetchClassMessages(classId: classId)) ?? []
        isLoading = false
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        Task {
            isSending = true
            let message = ClassChatMessage(
                studentId: profile.id,
                studentName: profile.displayName,
                message: newMessage
            )
            
            do {
                try await FirestoreService.shared.sendClassMessage(message, classId: classId)
                newMessage = ""
                await loadMessages()
            } catch {
                // Handle error silently
            }
            isSending = false
        }
    }
}

private struct MessageBubble: View {
    let message: ClassChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.studentName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(message.message)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color.appSecondaryGroupedBackground)
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if !message.approved {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text("Pending approval")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
