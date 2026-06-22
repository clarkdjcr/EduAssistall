import SwiftUI

// Phase 4: Quests view for students
struct QuestsView: View {
    let profile: UserProfile
    
    @State private var quests: [Quest] = []
    @State private var questProgress: [String: QuestProgress] = [:]
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                ProgressView("Loading quests...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if quests.isEmpty {
                emptyState
            } else {
                ForEach(quests) { quest in
                    QuestCard(
                        quest: quest,
                        progress: questProgress[quest.id],
                        profile: profile
                    )
                }
            }
        }
        .navigationTitle("Weekly Quests")
        .task {
            await loadData()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Active Quests")
                .font(.headline)
            Text("New quests will appear weekly")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadData() async {
        isLoading = true
        quests = (try? await FirestoreService.shared.fetchQuests(studentId: profile.id)) ?? []
        
        // Load progress for each quest
        for quest in quests {
            if let progress = try? await FirestoreService.shared.fetchQuestProgress(studentId: profile.id, questId: quest.id) {
                questProgress[quest.id] = progress
            }
        }
        
        isLoading = false
    }
}

private struct QuestCard: View {
    let quest: Quest
    let progress: QuestProgress?
    let profile: UserProfile
    
    @State private var showDetail = false
    
    private var questProgress: Double {
        guard let progress = progress else { return 0 }
        return QuestManager.calculateProgress(quest: quest, progress: progress)
    }
    
    private var isCompleted: Bool {
        guard let progress = progress else { return false }
        return QuestManager.isQuestComplete(quest: quest, progress: progress)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(quest.category == .learning ? Color.blue.opacity(0.15) :
                              quest.category == .social ? Color.green.opacity(0.15) :
                              quest.category == .exploration ? Color.purple.opacity(0.15) :
                              Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: quest.category.icon)
                        .font(.title2)
                        .foregroundStyle(quest.category == .learning ? .blue :
                                        quest.category == .social ? .green :
                                        quest.category == .exploration ? .purple :
                                        .orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.headline)
                    Text(quest.difficulty.displayName)
                        .font(.caption)
                        .foregroundStyle(quest.difficulty.color)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            
            Text(quest.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isCompleted ? Color.green : Color.blue)
                            .frame(width: geo.size.width * questProgress, height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("\(Int(questProgress * 100))% complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Rewards
            HStack(spacing: 16) {
                Label("\(quest.xpReward) XP", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.purple)
                
                if let badge = quest.badgeReward {
                    Label(badge.title, systemImage: badge.icon)
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            QuestDetailView(quest: quest, progress: progress, profile: profile)
        }
    }
}

// Phase 4: Quest detail view
struct QuestDetailView: View {
    let quest: Quest
    let progress: QuestProgress?
    let profile: UserProfile
    
    @Environment(\.dismiss) private var dismiss
    @State private var isClaiming = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(quest.category == .learning ? Color.blue.opacity(0.15) :
                                          quest.category == .social ? Color.green.opacity(0.15) :
                                          quest.category == .exploration ? Color.purple.opacity(0.15) :
                                          Color.orange.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                Image(systemName: quest.category.icon)
                                    .font(.title)
                                    .foregroundStyle(quest.category == .learning ? .blue :
                                                    quest.category == .social ? .green :
                                                    quest.category == .exploration ? .purple :
                                                    .orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quest.title)
                                    .font(.title2.bold())
                                Text(quest.difficulty.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(quest.difficulty.color)
                            }
                        }
                        
                        Text(quest.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tasks")
                            .font(.headline)
                        
                        ForEach(quest.tasks) { task in
                            TaskRow(task: task, progress: progress)
                        }
                    }
                    
                    Divider()
                    
                    // Rewards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rewards")
                            .font(.headline)
                        
                        HStack(spacing: 24) {
                            RewardItem(icon: "star.fill", label: "\(quest.xpReward) XP", color: .purple)
                            
                            if let badge = quest.badgeReward {
                                RewardItem(icon: badge.icon, label: badge.title, color: .yellow)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Claim button
                    if let progress = progress, QuestManager.isQuestComplete(quest: quest, progress: progress) {
                        Button {
                            claimRewards()
                        } label: {
                            HStack {
                                if isClaiming {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Claim Rewards")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isClaiming)
                    }
                }
                .padding()
            }
            .navigationTitle("Quest Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func claimRewards() {
        guard let progress = progress else { return }
        
        Task {
            isClaiming = true
            do {
                try await FirestoreService.shared.completeQuest(progressId: progress.id)
                try await QuestManager.awardQuestRewards(quest: quest, studentId: profile.id)
                dismiss()
            } catch {
                // Handle error
            }
            isClaiming = false
        }
    }
}

private struct TaskRow: View {
    let task: QuestTask
    let progress: QuestProgress?
    
    private var currentValue: Int {
        progress?.taskProgress[task.id] ?? 0
    }
    
    private var progressFraction: Double {
        guard task.targetValue > 0 else { return 0 }
        return Double(currentValue) / Double(task.targetValue)
    }
    
    private var isCompleted: Bool {
        currentValue >= task.targetValue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.description)
                    .font(.subheadline)
                Text("\(currentValue)/\(task.targetValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(progressFraction * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

private struct RewardItem: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
