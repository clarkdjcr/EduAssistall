import SwiftUI

struct PendingRecommendationsView: View {
    let reviewerProfile: UserProfile
    let studentIds: [String]

    @State private var recommendations: [Recommendation] = []
    @State private var isLoading = true
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                    recommendations.removeAll { $0.id == updated.id }
                                }
                            )
                        } label: {
                            RecommendationRow(recommendation: rec)
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
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: recommendation.type.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                Text(recommendation.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text(recommendation.rationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                // NYC DOE: educators must know this is AI-generated and requires their review.
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("AI generated · Requires your review")
                        .font(.caption2)
                }
                .foregroundStyle(.purple.opacity(0.8))
            }

            Spacer()

            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
    }
}
