import SwiftUI

struct ContentItemView: View {
    let item: ContentItem
    let studentId: String
    let existingProgress: StudentProgress?
    let onProgressUpdated: (StudentProgress) -> Void

    @State private var isComplete: Bool = false
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(item: ContentItem, studentId: String,
         existingProgress: StudentProgress?,
         onProgressUpdated: @escaping (StudentProgress) -> Void) {
        self.item = item
        self.studentId = studentId
        self.existingProgress = existingProgress
        self.onProgressUpdated = onProgressUpdated
        self._isComplete = State(initialValue: existingProgress?.status == .completed)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Meta row
                HStack(spacing: 10) {
                    Label(item.contentType.displayName, systemImage: item.contentType.icon)
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())

                    Label("\(item.estimatedMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !item.subject.isEmpty {
                        Label(item.subject, systemImage: "books.vertical")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Description
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                // Content display
                switch item.contentType {
                case .video, .article:
                    contentLinkCard
                case .quiz:
                    quizLaunchCard
                }

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(item.title)
        .inlineNavigationTitle()
        .safeAreaInset(edge: .bottom) {
            if item.contentType != .quiz {
                completeButton
            }
        }
    }

    // MARK: - Content Link Card

    private var contentLinkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.contentType == .video ? "play.rectangle.fill" : "safari.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.contentType == .video ? "Watch Video" : "Read Article")
                        .font(.headline)
                    Text("Opens in browser")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let url = URL(string: item.url), !item.url.isEmpty {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text(item.contentType == .video ? "Open Video" : "Open Article")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Text("No URL provided for this content item.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Quiz Launch Card

    private var quizLaunchCard: some View {
        NavigationLink {
            QuizView(item: item, studentId: studentId, onProgressUpdated: onProgressUpdated)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.square.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Take Quiz")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Answer questions to complete this item")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            guard !isComplete else { return }
            Task { await markComplete() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView().tint(Color.white)
                } else if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Completed")
                        .fontWeight(.semibold)
                } else {
                    Image(systemName: "circle")
                    Text("Mark as Complete")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isComplete ? Color.green : Color.blue)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isComplete || isSaving)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.appGroupedBackground)
    }

    private func markComplete() async {
        isSaving = true
        var progress = existingProgress ?? StudentProgress(studentId: studentId, contentItemId: item.id)
        progress.markComplete()
        do {
            try await FirestoreService.shared.saveProgress(progress)
            isComplete = true
            onProgressUpdated(progress)
            // Fire-and-forget: ask AI to generate recommendations for this student
            Task {
                try? await CloudFunctionService.shared.generateRecommendations(studentId: studentId)
            }
        } catch {
            // Silently fail — UI stays in original state
        }
        isSaving = false
    }
}
