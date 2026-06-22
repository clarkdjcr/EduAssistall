import SwiftUI

// Phase 4: Content recommendations view
struct RecommendationsView: View {
    let profile: UserProfile
    let learningProfile: LearningProfile?
    
    @State private var recommendations: [ContentRecommendation] = []
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading recommendations...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if recommendations.isEmpty {
                emptyState
            } else {
                ForEach(recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                        .onTapGesture {
                            Task {
                                try? await FirestoreService.shared.markRecommendationViewed(recommendationId: recommendation.id)
                            }
                        }
                }
            }
        }
        .navigationTitle("For You")
        .task {
            await loadRecommendations()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Recommendations Yet")
                .font(.headline)
            Text("Recommendations based on your interests will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadRecommendations() async {
        isLoading = true
        recommendations = (try? await FirestoreService.shared.fetchRecommendations(studentId: profile.id)) ?? []
        isLoading = false
    }
}

private struct RecommendationCard: View {
    let recommendation: ContentRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended for You")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Text(recommendation.contentTitle)
                        .font(.headline)
                }
                
                Spacer()
                
                if !recommendation.isViewed {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(recommendation.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(formatDate(recommendation.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                Spacer()
                
                Text("\(Int(recommendation.relevanceScore * 100))% match")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
