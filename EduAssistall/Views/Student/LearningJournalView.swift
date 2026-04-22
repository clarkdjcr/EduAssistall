import SwiftUI

struct LearningJournalView: View {
    let profile: UserProfile

    @State private var entries: [LearningJournalEntry] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entries.isEmpty {
                emptyState
            } else {
                entryList
            }
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Learning Journal")
        .inlineNavigationTitle()
        .task { await load() }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 56))
                .foregroundStyle(.orange.opacity(0.5))
            Text("Your journal is empty")
                .font(.title3.bold())
            Text("After each AI companion session, a summary will appear here automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var entryList: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink {
                    JournalEntryDetailView(entry: entry)
                } label: {
                    JournalEntryRow(entry: entry)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    private func load() async {
        isLoading = true
        entries = (try? await FirestoreService.shared.fetchJournalEntries(studentId: profile.id)) ?? []
        isLoading = false
    }
}

// MARK: - Entry Row

private struct JournalEntryRow: View {
    let entry: LearningJournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.sessionDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(entry.summary)
                .font(.subheadline)
                .lineLimit(2)

            if !entry.keyTopics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.keyTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Entry Detail

private struct JournalEntryDetailView: View {
    let entry: LearningJournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.sessionDate.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(entry.messageCount) exchanges with AI companion")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What you learned")
                        .font(.headline)
                    Text(entry.summary)
                        .font(.body)
                }

                if !entry.keyTopics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics covered")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(entry.keyTopics, id: \.self) { topic in
                                Text(topic)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.12))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Journal Entry")
        .inlineNavigationTitle()
    }
}

// MARK: - Simple Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                          proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
