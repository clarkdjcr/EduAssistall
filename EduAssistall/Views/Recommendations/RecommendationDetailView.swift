import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: Recommendation
    let reviewerProfile: UserProfile
    let onReviewed: (Recommendation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isActing = false
    @State private var actionTaken: RecommendationStatus?
    @State private var errorMessage: String?
    @State private var showRejectConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // NYC DOE: AI-generated content must be labeled and require educator sign-off.
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text(reviewBadgeText)
                        .font(.caption2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Type badge + title
                VStack(alignment: .leading, spacing: 12) {
                    Label(typeLabel, systemImage: recommendation.type.icon)
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())

                    Text(recommendation.title)
                        .font(.title2.bold())
                }

                // AI Rationale
                VStack(alignment: .leading, spacing: 8) {
                    Label("Why the AI recommends this", systemImage: "brain.filled.head.profile")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(recommendation.rationale)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Lesson plan content — shown when available so reviewers can read what students will receive
                if let planText = recommendation.lessonPlanText, !planText.isEmpty {
                    lessonPlanCard(planText)
                }

                // Date
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Generated \(recommendation.createdAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 100)
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Recommendation")
        .inlineNavigationTitle()
        .sensoryFeedback(.success, trigger: actionTaken == .approved)
        .sensoryFeedback(.warning, trigger: actionTaken == .rejected)
        .confirmationDialog(
            "Reject this recommendation?",
            isPresented: $showRejectConfirm,
            titleVisibility: .visible
        ) {
            Button("Reject", role: .destructive) {
                Task { await act(status: .rejected) }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The student won't see this AI suggestion. This can't be undone.")
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button("Dismiss") { withAnimation { errorMessage = nil } }
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.08))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if actionTaken == nil {
                    actionButtons
                } else {
                    actionConfirmation
                }
            }
            .animation(.easeInOut(duration: 0.25), value: errorMessage)
        }
    }

    // MARK: - Lesson Plan Card

    private func lessonPlanCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Lesson Plan Content", systemImage: "doc.text.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Students will receive this")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Text(text)
                .font(.callout)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showRejectConfirm = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Reject")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.9))
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isActing)

            Button {
                Task { await act(status: .approved) }
            } label: {
                HStack {
                    if isActing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isActing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.appGroupedBackground)
    }

    private var actionConfirmation: some View {
        HStack(spacing: 10) {
            Image(systemName: actionTaken == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(actionTaken == .approved ? Color.green : Color.red)
            VStack(alignment: .leading, spacing: 2) {
                Text(actionTaken == .approved ? "Approved" : "Rejected")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(actionConfirmationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.appSecondaryGroupedBackground)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }

    // MARK: - Helpers

    private var typeLabel: String {
        switch recommendation.type {
        case .learningPath: return "Learning Path"
        case .contentItem:  return "Content Item"
        case .quiz:         return "Quiz"
        case .lessonPlan:   return "Lesson Plan"
        case .lessonDay:    return "Teaching Day"
        }
    }

    private var isLessonWorkflowRecommendation: Bool {
        recommendation.type == .lessonPlan || recommendation.type == .lessonDay
    }

    private var reviewBadgeText: String {
        isLessonWorkflowRecommendation
            ? "AI generated · Teacher approval required before assignment"
            : "AI generated · Human review required before student sees this"
    }

    private var actionConfirmationText: String {
        guard actionTaken == .approved else {
            return "Removed from queue. The student won't see this."
        }
        if isLessonWorkflowRecommendation {
            return "Approved for the lesson workflow. Students receive it when daily assignments are created."
        }
        return "Student can now see this recommendation."
    }

    private func act(status: RecommendationStatus) async {
        isActing = true
        errorMessage = nil
        do {
            try await FirestoreService.shared.updateRecommendationStatus(
                id: recommendation.id,
                status: status,
                reviewedBy: reviewerProfile.id
            )
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                actionTaken = status
            }
            var updated = recommendation
            updated.status = status
            onReviewed(updated)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        } catch {
            withAnimation { errorMessage = "Failed to save. Please try again." }
        }
        isActing = false
    }
}
