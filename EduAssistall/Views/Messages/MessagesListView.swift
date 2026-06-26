import SwiftUI

struct MessagesListView: View {
    let profile: UserProfile

    @State private var vm = MessagingViewModel()
    @State private var showCompose = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    SkeletonThreadRows()
                } else if vm.threads.isEmpty {
                    emptyState
                } else {
                    List(vm.threads) { thread in
                        NavigationLink {
                            MessageThreadView(thread: thread, currentUser: profile)
                        } label: {
                            ThreadRow(thread: thread, currentUserId: profile.id)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                    .animation(.easeInOut(duration: 0.25), value: vm.threads.count)
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
                    .accessibilityLabel("Compose new message")
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeMessageView(currentUser: profile, vm: vm)
                    .macSheetFrame(width: 760, height: 620)
            }
            .onAppear { vm.startListening(userId: profile.id) }
            .onDisappear { vm.stopListening() }
            .refreshable { await vm.loadThreads(userId: profile.id) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text("No Messages Yet")
                .font(.title3.bold())
            Text("Start a conversation with a teacher or parent about a student.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showCompose = true
            } label: {
                Label("New Message", systemImage: "square.and.pencil")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Thread Row

struct ThreadRow: View {
    let thread: MessageThread
    let currentUserId: String

    var body: some View {
        HStack(spacing: 12) {
            avatarView
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(thread.otherParticipantName(currentUserId: currentUserId))
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Text(thread.studentName)
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())

                    if let last = thread.lastMessage {
                        Text(last)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var avatarView: some View {
        let name = thread.otherParticipantName(currentUserId: currentUserId)
        let initial = name.first.map(String.init) ?? "?"
        return ZStack {
            Circle()
                .fill(avatarColor(for: name))
            Text(initial.uppercased())
                .font(.subheadline.bold())
                .foregroundStyle(.white)
        }
        .frame(width: 42, height: 42)
    }

    private var formattedDate: String {
        let date = thread.lastMessageAt ?? thread.createdAt
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(.relative(presentation: .named))
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .teal, .indigo, .orange, .pink, .green]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Skeleton Loading

private struct SkeletonThreadRows: View {
    @State private var pulsing = false

    var body: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in skeletonRow }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .opacity(pulsing ? 0.45 : 1.0)
        .animation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true), value: pulsing)
        .allowsHitTesting(false)
        .onAppear { pulsing = true }
    }

    private var skeletonRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 140, height: 13)
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 220, height: 11)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
