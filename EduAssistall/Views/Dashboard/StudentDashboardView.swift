import SwiftUI

struct StudentDashboardView: View {
    let profile: UserProfile

    @State private var learningProfile: LearningProfile?
    @State private var activePath: LearningPath?
    @State private var completedCount: Int = 0
    @State private var currentStreak: Int = 0
    @State private var thisWeekPercent: Int = 0
    @State private var milestones: [LearningMilestone] = []       // FR-300
    @State private var recentMessages: [ChatMessage] = []         // FR-300
    @State private var approvedRecs: [Recommendation] = []
    @State private var isLoading = true
    @State private var showProfile = false
    @State private var pendingLinks: [StudentAdultLink] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greetingText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(profile.displayName)
                            .font(.largeTitle.bold())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // COPPA: pending link-request banner — shown at top so student can't miss it
                    if !pendingLinks.isEmpty {
                        NavigationLink {
                            PendingLinksView(studentId: profile.id)
                        } label: {
                            PendingLinksBanner(count: pendingLinks.count)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }

                    // Stats Row
                    HStack(spacing: 12) {
                        StatCard(
                            value: "\(currentStreak)",
                            label: "Day Streak",
                            icon: "flame.fill",
                            color: currentStreak > 0 ? .orange : .secondary
                        )
                        StatCard(
                            value: "\(thisWeekPercent)%",
                            label: "This Week",
                            icon: "chart.line.uptrend.xyaxis",
                            color: thisWeekPercent > 0 ? .green : .secondary
                        )
                        StatCard(
                            value: "\(completedCount)",
                            label: "Lessons Done",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )
                    }
                    .padding(.horizontal, 20)

                    // Learning Style Card
                    if let lp = learningProfile, let style = lp.learningStyle {
                        LearningStyleCard(style: style)
                            .padding(.horizontal, 20)
                    }

                    // Continue Learning CTA
                    Group {
                        if let path = activePath {
                            NavigationLink {
                                LearningPathDetailView(path: path, studentId: profile.id)
                            } label: {
                                ContinueLearningLabel(subtitle: path.title)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ContinueLearningLabel(subtitle: "Your learning paths are being set up")
                                .opacity(0.7)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Upcoming Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming")
                            .font(.headline)
                            .padding(.horizontal, 20)

                        EmptyStateCard(
                            icon: "calendar",
                            message: "No upcoming assignments yet.\nCheck back after your teacher sets up your learning path."
                        )
                        .padding(.horizontal, 20)
                    }

                    // Interests
                    if let lp = learningProfile, !lp.interests.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Interests")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(lp.interests, id: \.self) { interest in
                                        Text(interest)
                                            .font(.subheadline)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundStyle(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // FR-300: Achievements
                    if !milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Achievements")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            ForEach(milestones) { milestone in
                                MilestoneCard(milestone: milestone)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    // Educator-approved AI recommendations
                    if !approvedRecs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Text("Recommended for You")
                                    .font(.headline)
                                Spacer()
                                // NYC DOE: students must always know AI was involved.
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                    Text("AI suggested")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.purple.opacity(0.8))
                            }
                            .padding(.horizontal, 20)

                            ForEach(approvedRecs.prefix(3)) { rec in
                                ApprovedRecommendationCard(recommendation: rec)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    // FR-300: Goals CTA (goal-setting flow in FR-301)
                    NavigationLink {
                        GoalSettingView(profile: profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Goals")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                                Text("Set and track your learning goals")
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "target")
                                .font(.title2)
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.indigo, Color.purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    // FR-302: Learning Journal CTA
                    NavigationLink {
                        LearningJournalView(profile: profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Learning Journal")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                                Text("Auto-generated summaries of your sessions")
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "book.closed.fill")
                                .font(.title2)
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    // FR-300: Recent Interactions
                    if !recentMessages.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent AI Interactions")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(recentMessages) { msg in
                                    RecentMessageRow(message: msg)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // Test Prep card
                    NavigationLink {
                        TestPrepView(profile: profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Test Prep")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                                Text("SAT, ACT, and standards practice")
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.title2)
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.teal, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    // Explore Careers card
                    NavigationLink {
                        CareerExplorerView(profile: profile)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Explore Careers")
                                    .font(.headline)
                                    .foregroundStyle(Color.white)
                                Text("Discover paths that match your interests")
                                    .font(.caption)
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "briefcase.fill")
                                .font(.title2)
                                .foregroundStyle(Color.white.opacity(0.9))
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Dashboard")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                StudentProfileSheet()
            }
            .task {
                await loadProfile()
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }

    private func loadProfile() async {
        isLoading = true
        async let profileFetch = FirestoreService.shared.fetchLearningProfile(studentId: profile.id)
        async let pathsFetch = FirestoreService.shared.fetchLearningPaths(studentId: profile.id)
        async let progressFetch = FirestoreService.shared.fetchAllProgress(studentId: profile.id)
        async let milestonesFetch = FirestoreService.shared.fetchRecentMilestones(studentId: profile.id, limit: 3)
        async let messagesFetch = FirestoreService.shared.fetchRecentConversationMessages(studentId: profile.id, limit: 4)

        learningProfile = try? await profileFetch
        milestones = (try? await milestonesFetch) ?? []
        recentMessages = (try? await messagesFetch) ?? []
        approvedRecs = (try? await FirestoreService.shared.fetchRecommendations(studentId: profile.id)) ?? []

        let paths = (try? await pathsFetch) ?? []
        activePath = paths.first(where: { $0.isActive }) ?? paths.first

        let allProgress = (try? await progressFetch) ?? []
        let completed = allProgress.filter { $0.status == .completed }
        completedCount = completed.count
        currentStreak = calculateStreak(from: completed)
        thisWeekPercent = calculateThisWeekPercent(from: completed, total: allProgress.count)

        isLoading = false

        // Load pending link requests separately — don't block the main content load.
        pendingLinks = (try? await FirestoreService.shared.fetchPendingLinks(studentId: profile.id)) ?? []
    }

    private func calculateStreak(from completed: [StudentProgress]) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let completionDays = Set(completed.compactMap { $0.completedAt }.map { cal.startOfDay(for: $0) })
        var streak = 0
        var day = today
        while completionDays.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private func calculateThisWeekPercent(from completed: [StudentProgress], total: Int) -> Int {
        guard total > 0 else { return 0 }
        let cal = Calendar.current
        let now = Date()
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekEnd = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        let thisWeek = completed.filter {
            guard let d = $0.completedAt else { return false }
            return d >= weekStart && d < weekEnd
        }.count
        return Int(Double(thisWeek) / Double(total) * 100)
    }
}

// MARK: - Supporting Views

private struct ContinueLearningLabel: View {
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Continue Learning")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct LearningStyleCard: View {
    let style: LearningStyle

    private var styleIcon: String {
        switch style {
        case .visual: return "eye.fill"
        case .auditory: return "waveform"
        case .kinesthetic: return "hand.raised.fill"
        case .readWrite: return "text.alignleft"
        }
    }

    private var styleColor: Color {
        switch style {
        case .visual: return .purple
        case .auditory: return .orange
        case .kinesthetic: return .green
        case .readWrite: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: styleIcon)
                .font(.title2)
                .foregroundStyle(styleColor)
                .frame(width: 44, height: 44)
                .background(styleColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Learning Style")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(style.displayName)
                    .font(.headline)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Student Profile Sheet

struct StudentProfileSheet: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var pendingCount = 0

    var body: some View {
        NavigationStack {
            List {
                if let profile = authVM.currentProfile {
                    Section {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(profile.displayName.prefix(1).uppercased())
                                        .font(.title2.bold())
                                        .foregroundStyle(.blue)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName)
                                    .font(.headline)
                                Text(profile.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }

                    Section {
                        NavigationLink {
                            PendingLinksView(studentId: profile.id)
                        } label: {
                            HStack {
                                Label("Link Requests", systemImage: "person.badge.plus")
                                Spacer()
                                if pendingCount > 0 {
                                    Text("\(pendingCount)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        NavigationLink {
                            DataPrivacyView()
                        } label: {
                            Label("Privacy & Data", systemImage: "lock.shield")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.signOut()
                        dismiss()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if let id = authVM.currentProfile?.id {
                    let pending = (try? await FirestoreService.shared.fetchPendingLinks(studentId: id)) ?? []
                    // Only count non-expired requests (expired ones are cleaned up nightly but may
                    // linger briefly; filter client-side so the badge stays accurate).
                    pendingCount = pending.filter { $0.expiresAt > Date() }.count
                }
            }
        }
    }
}

// MARK: - FR-300 Supporting Views

private struct MilestoneCard: View {
    let milestone: LearningMilestone

    private var icon: String {
        switch milestone.type {
        case .contentCompleted: return "checkmark.circle.fill"
        case .quizPassed:       return "star.fill"
        case .pathCompleted:    return "trophy.fill"
        case .topicMastered:    return "seal.fill"
        }
    }

    private var color: Color {
        switch milestone.type {
        case .contentCompleted: return .blue
        case .quizPassed:       return .orange
        case .pathCompleted:    return .yellow
        case .topicMastered:    return .green
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(milestone.type.verb.capitalized) • \(milestone.subject)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(milestone.achievedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct RecentMessageRow: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isUser ? "person.circle.fill" : "brain.filled.head.profile")
                .font(.subheadline)
                .foregroundStyle(isUser ? Color.secondary : Color.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(isUser ? "You" : "AI Companion")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(message.text)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct EmptyStateCard: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Approved Recommendation Card

private struct ApprovedRecommendationCard: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: recommendation.type.icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 40, height: 40)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(recommendation.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Text(recommendation.rationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                // NYC DOE: make AI origin and educator approval explicit to the student.
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("AI suggested · Approved by your teacher")
                        .font(.caption2)
                }
                .foregroundStyle(.purple.opacity(0.7))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - COPPA: Pending Links Banner

private struct PendingLinksBanner: View {
    let count: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.badge.clock.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(count == 1 ? "1 Link Request Waiting" : "\(count) Link Requests Waiting")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text("A parent or teacher wants to connect to your account. Tap to review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.orange.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("\(count) pending link \(count == 1 ? "request" : "requests")")
        .accessibilityHint("Tap to review and approve or decline")
    }
}
