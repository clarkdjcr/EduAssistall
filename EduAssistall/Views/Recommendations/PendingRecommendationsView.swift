import SwiftUI

struct PendingRecommendationsView: View {
    let reviewerProfile: UserProfile
    let studentIds: [String]

    @State private var recommendations: [Recommendation] = []
    @State private var isLoading = true
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var rejectTarget: Recommendation?

    var body: some View {
        Group {
            if isLoading {
                SkeletonRecommendationRows()
            } else if recommendations.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(recommendations) { rec in
                        NavigationLink {
                            RecommendationDetailView(
                                recommendation: rec,
                                reviewerProfile: reviewerProfile,
                                onReviewed: { updated in
                                    withAnimation {
                                        recommendations.removeAll { $0.id == updated.id }
                                    }
                                }
                            )
                        } label: {
                            RecommendationRow(recommendation: rec)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task { await swipeAct(rec, status: .approved) }
                            } label: {
                                Label("Approve", systemImage: "checkmark.circle.fill")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                rejectTarget = rec
                            } label: {
                                Label("Reject", systemImage: "xmark.circle.fill")
                            }
                        }
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
        .navigationTitle("Pending Reviews")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await generateForAllStudents() }
                } label: {
                    if isGenerating {
                        ProgressView().tint(.blue)
                    } else {
                        Label("Generate", systemImage: "wand.and.stars")
                    }
                }
                .disabled(isGenerating || studentIds.isEmpty)
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .confirmationDialog(
            "Reject this recommendation?",
            isPresented: Binding(
                get: { rejectTarget != nil },
                set: { if !$0 { rejectTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Reject", role: .destructive) {
                if let target = rejectTarget {
                    Task { await swipeAct(target, status: .rejected) }
                }
                rejectTarget = nil
            }
            Button("Cancel", role: .cancel) { rejectTarget = nil }
        } message: {
            Text("The student won't see this AI suggestion. This can't be undone.")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.opacity(0.6))
            Text("All Caught Up")
                .font(.title3.bold())
            Text("No pending AI recommendations to review.\nTap the wand button to generate new ones for your students.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if !studentIds.isEmpty {
                Button {
                    Task { await generateForAllStudents() }
                } label: {
                    Label(isGenerating ? "Generating…" : "Generate Recommendations",
                          systemImage: "wand.and.stars")
                        .fontWeight(.semibold)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isGenerating)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func load() async {
        isLoading = true
        recommendations = (try? await FirestoreService.shared.fetchPendingRecommendations(studentIds: studentIds)) ?? []
        isLoading = false
    }

    private func generateForAllStudents() async {
        isGenerating = true
        for studentId in studentIds {
            try? await CloudFunctionService.shared.generateRecommendations(studentId: studentId)
        }
        await load()
        isGenerating = false
    }

    private func swipeAct(_ rec: Recommendation, status: RecommendationStatus) async {
        try? await FirestoreService.shared.updateRecommendationStatus(
            id: rec.id,
            status: status,
            reviewedBy: reviewerProfile.id
        )
        withAnimation {
            recommendations.removeAll { $0.id == rec.id }
        }
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: recommendation.type.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text(recommendation.rationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("AI generated")
                            .font(.caption2)
                    }
                    .foregroundStyle(.purple.opacity(0.8))

                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(recommendation.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Text("Pending")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Skeleton Loading

private struct SkeletonRecommendationRows: View {
    @State private var pulsing = false

    var body: some View {
        List {
            ForEach(0..<4, id: \.self) { _ in
                skeletonRow
            }
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
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 180, height: 13)
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 240, height: 11)
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 120, height: 10)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
