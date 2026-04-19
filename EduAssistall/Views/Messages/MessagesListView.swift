import SwiftUI

struct MessagesListView: View {
    let profile: UserProfile

    @State private var threads: [MessageThread] = []
    @State private var isLoading = true
    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if threads.isEmpty {
                    emptyState
                } else {
                    List(threads) { thread in
                        NavigationLink {
                            MessageThreadView(thread: thread, currentUser: profile)
                        } label: {
                            ThreadRow(thread: thread, currentUserId: profile.id)
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Messages")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showCompose, onDismiss: {
                Task { await load() }
            }) {
                ComposeMessageView(currentUser: profile)
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Messages Yet")
                .font(.title3.bold())
            Text("Tap the compose button to start a conversation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        let loaded = (try? await FirestoreService.shared.fetchMessageThreads(userId: profile.id)) ?? []
        threads = loaded.sorted {
            ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt)
        }
        isLoading = false
    }
}

// MARK: - Thread Row

private struct ThreadRow: View {
    let thread: MessageThread
    let currentUserId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(thread.otherParticipantName(currentUserId: currentUserId))
                    .font(.subheadline.bold())
                Spacer()
                if let date = thread.lastMessageAt ?? Optional(thread.createdAt) {
                    Text(date.formatted(.relative(presentation: .numeric)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Re: \(thread.studentName)")
                .font(.caption)
                .foregroundStyle(.blue)
            if let last = thread.lastMessage {
                Text(last)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
