import SwiftUI

struct RecommendationDetailView: View {
    let recommendation: Recommendation
    let reviewerProfile: UserProfile
    let onReviewed: (Recommendation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isActing = false
    @State private var actionTaken: RecommendationStatus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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

                // Date
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Generated \(recommendation.createdAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 80)
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Recommendation")
        .inlineNavigationTitle()
        .safeAreaInset(edge: .bottom) {
            if actionTaken == nil {
                actionButtons
            } else {
                actionConfirmation
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await act(status: .rejected) }
            } label: {
                HStack {
                    if isActing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                            .fontWeight(.semibold)
                    }
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
        HStack {
            Image(systemName: actionTaken == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(actionTaken == .approved ? Color.green : Color.red)
            Text(actionTaken == .approved ? "Approved — student can now see this recommendation." : "Rejected and removed from queue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.appSecondaryGroupedBackground)
    }

    // MARK: - Helpers

    private var typeLabel: String {
        switch recommendation.type {
        case .learningPath: return "Learning Path"
        case .contentItem:  return "Content Item"
        case .quiz:         return "Quiz"
        }
    }

    private func act(status: RecommendationStatus) async {
        isActing = true
        do {
            try await FirestoreService.shared.updateRecommendationStatus(
                id: recommendation.id,
                status: status,
                reviewedBy: reviewerProfile.id
            )
            actionTaken = status
            var updated = recommendation
            updated.status = status
            onReviewed(updated)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            dismiss()
        } catch {
            // Stay on screen — Firestore error
        }
        isActing = false
    }
}
