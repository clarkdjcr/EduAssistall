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
                    JournalEntryDetailView(entry: entry) { updated in
                        if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                            entries[index] = updated
                        }
                    }
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

            Text(entry.displaySummary)
                .font(.subheadline)
                .lineLimit(2)

            if !entry.displayKeyTopics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.displayKeyTopics, id: \.self) { topic in
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
    let onUpdate: (LearningJournalEntry) -> Void

    @State private var draftReflection: String
    @State private var shareWithTeacher: Bool
    @State private var shareWithParent: Bool
    @State private var savedEntry: LearningJournalEntry
    @State private var isSaving = false
    @State private var saveMessage: String?
    @State private var errorMessage: String?

    init(entry: LearningJournalEntry, onUpdate: @escaping (LearningJournalEntry) -> Void) {
        self.entry = entry
        self.onUpdate = onUpdate
        _draftReflection = State(initialValue: entry.privateReflection ?? "")
        _shareWithTeacher = State(initialValue: entry.shareWithTeacher)
        _shareWithParent = State(initialValue: entry.shareWithParent)
        _savedEntry = State(initialValue: entry)
    }

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
                    Text("What you accomplished")
                        .font(.headline)
                    Text(entry.displaySummary)
                        .font(.body)
                }

                if !entry.displayKeyTopics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics covered")
                            .font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(entry.displayKeyTopics, id: \.self) { topic in
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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Private reflection")
                        .font(.headline)

                    JournalWritingGuide()

                    TextEditor(text: $draftReflection)
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Toggle("Share with my teacher", isOn: $shareWithTeacher)
                    Toggle("Share with my parent", isOn: $shareWithParent)

                    if let statusText {
                        Label(statusText, systemImage: statusIcon)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let saveMessage {
                        Label(saveMessage, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: saveReflection) {
                        if isSaving {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Saving...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Save Reflection", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving || !hasChanges)
                }
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Journal Entry")
        .inlineNavigationTitle()
    }

    private var hasChanges: Bool {
        draftReflection != (savedEntry.privateReflection ?? "") ||
        shareWithTeacher != savedEntry.shareWithTeacher ||
        shareWithParent != savedEntry.shareWithParent
    }

    private var statusText: String? {
        switch savedEntry.reflectionSafetyStatus {
        case "safe":
            return savedEntry.reflectionUpdatedAt == nil ? nil : "Reflection saved"
        case "needs_review":
            return "Reflection saved and flagged for safety review"
        case "not_submitted", nil:
            return nil
        default:
            return savedEntry.reflectionSafetyStatus
        }
    }

    private var statusIcon: String {
        savedEntry.reflectionSafetyStatus == "needs_review" ? "shield.lefthalf.filled" : "lock.fill"
    }

    private var statusColor: Color {
        savedEntry.reflectionSafetyStatus == "needs_review" ? .orange : .secondary
    }

    private func saveReflection() {
        errorMessage = nil
        saveMessage = nil
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let result = try await CloudFunctionService.shared.saveJournalReflection(
                    studentId: savedEntry.studentId,
                    entryId: savedEntry.id,
                    reflection: draftReflection,
                    shareWithTeacher: shareWithTeacher,
                    shareWithParent: shareWithParent
                )
                draftReflection = result.reflection
                savedEntry.privateReflection = result.reflection
                savedEntry.shareWithTeacher = shareWithTeacher
                savedEntry.shareWithParent = shareWithParent
                savedEntry.reflectionSafetyStatus = result.safetyStatus
                savedEntry.reflectionSafetyReason = result.safetyReason
                savedEntry.reflectionUpdatedAt = Date()
                saveMessage = "Reflection saved"
                onUpdate(savedEntry)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct JournalWritingGuide: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                GuideStep(number: 1, title: "Start with the day", text: "Name the topic, task, or problem you worked on.")
                GuideStep(number: 2, title: "Explain the learning", text: "Write one or two sentences about the idea you understand better now.")
                GuideStep(number: 3, title: "Use mistakes as clues", text: "If something did not work, name the step that broke down and what helped correct it.")
                GuideStep(number: 4, title: "Notice the hard part", text: "Describe what confused you, slowed you down, or made you think.")
                GuideStep(number: 5, title: "Choose a next move", text: "End with one question, goal, or strategy you want to try next time.")
            }
            .padding(.top, 8)
        } label: {
            Label("Journal writing guide", systemImage: "pencil.and.outline")
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct GuideStep: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.orange, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.bold())
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
