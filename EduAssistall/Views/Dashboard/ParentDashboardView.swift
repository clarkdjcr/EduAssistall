import SwiftUI

struct ParentDashboardView: View {
    let profile: UserProfile

    @State private var linkedStudents: [StudentAdultLink] = []
    @State private var progressSummaries: [String: (completed: Int, total: Int)] = [:]
    @State private var pendingRecs: [Recommendation] = []
    @State private var recentActivity: [(studentId: String, email: String, progress: StudentProgress)] = []
    @State private var isLoading = true

    private var confirmedStudents: [StudentAdultLink] { linkedStudents.filter(\.confirmed) }
    private var studentIds: [String] { confirmedStudents.map(\.studentId) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    greetingHeader
                    if !confirmedStudents.isEmpty { summaryCards }
                    if !pendingRecs.isEmpty { pendingSection }
                    childrenSection
                    recentActivitySection
                    quickActions
                    Spacer(minLength: 32)
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Parent Dashboard")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back,")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(profile.displayName)
                .font(.largeTitle.bold())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            let totalCompleted = progressSummaries.values.map(\.completed).reduce(0, +)
            let totalItems = progressSummaries.values.map(\.total).reduce(0, +)

            ParentStatCard(value: "\(confirmedStudents.count)",
                           label: "Children", icon: "person.2.fill", color: .blue)
            ParentStatCard(value: "\(totalCompleted)/\(totalItems)",
                           label: "Lessons Done", icon: "checkmark.circle.fill", color: .green)
            ParentStatCard(value: "\(pendingRecs.count)",
                           label: "To Review", icon: "checkmark.shield.fill",
                           color: pendingRecs.isEmpty ? .secondary : .orange,
                           highlight: !pendingRecs.isEmpty)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Pending Recommendations (inline one-tap approve)

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Needs Your Review", systemImage: "exclamationmark.shield.fill")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
                NavigationLink("See All") {
                    PendingRecommendationsView(reviewerProfile: profile, studentIds: studentIds)
                }
                .font(.subheadline)
                .foregroundStyle(.blue)
            }
            .padding(.horizontal, 20)

            ForEach(pendingRecs.prefix(2)) { rec in
                InlinePendingRecCard(rec: rec, reviewerProfile: profile) {
                    await load()
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Children Section

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Children")
                .font(.headline)
                .padding(.horizontal, 20)

            if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if confirmedStudents.isEmpty {
                ParentEmptyState().padding(.horizontal, 20)
            } else {
                ForEach(confirmedStudents) { link in
                    NavigationLink {
                        StudentProgressDetailView(studentId: link.studentId,
                                                  studentEmail: link.studentEmail)
                    } label: {
                        LinkedStudentCard(link: link,
                                         summary: progressSummaries[link.studentId])
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal, 20)

            if recentActivity.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("Activity will appear here once your child starts learning.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            } else {
                ForEach(recentActivity.prefix(5), id: \.progress.id) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.email)
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text("Completed a lesson")
                                .font(.subheadline)
                        }
                        Spacer()
                        if let date = item.progress.completedAt {
                            Text(date.formatted(.relative(presentation: .numeric)))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(12)
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                NavigationLink {
                    ParentReportsDestination(confirmedStudents: confirmedStudents)
                } label: {
                    ParentActionTile(icon: "doc.text.fill", label: "View Reports", color: .blue)
                }
                .buttonStyle(.plain)
                .disabled(confirmedStudents.isEmpty)

                NavigationLink {
                    PendingRecommendationsView(reviewerProfile: profile, studentIds: studentIds)
                } label: {
                    ParentActionTile(icon: "checkmark.shield.fill", label: "Review Content",
                                     color: .green, badge: pendingRecs.isEmpty ? nil : "\(pendingRecs.count)")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    MessagesListView(profile: profile)
                } label: {
                    ParentActionTile(icon: "message.fill", label: "Message Teacher", color: .purple)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ParentProgressDestination(confirmedStudents: confirmedStudents)
                } label: {
                    ParentActionTile(icon: "chart.bar.fill", label: "Progress", color: .orange)
                }
                .buttonStyle(.plain)
                .disabled(confirmedStudents.isEmpty)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        let linked = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: profile.id)) ?? []
        linkedStudents = linked

        let ids = confirmedStudents.map(\.studentId)
        pendingRecs = (try? await FirestoreService.shared.fetchPendingRecommendations(studentIds: ids)) ?? []

        var summaries: [String: (Int, Int)] = [:]
        var activity: [(studentId: String, email: String, progress: StudentProgress)] = []

        await withTaskGroup(of: (String, String, Int, Int, [StudentProgress]).self) { group in
            for link in confirmedStudents {
                group.addTask {
                    async let fetchPaths = FirestoreService.shared.fetchAllLearningPaths(studentId: link.studentId)
                    async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: link.studentId)
                    let paths = (try? await fetchPaths) ?? []
                    let prog = (try? await fetchProgress) ?? []
                    let map = Dictionary(uniqueKeysWithValues: prog.map { ($0.contentItemId, $0) })
                    let all = paths.flatMap(\.items)
                    let done = all.filter { map[$0.contentItemId]?.status == .completed }.count
                    let recent = prog.filter { $0.status == .completed }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
                    return (link.studentId, link.studentEmail, done, all.count, recent)
                }
            }
            for await (sid, email, done, total, recent) in group {
                summaries[sid] = (done, total)
                activity += recent.prefix(3).map { (sid, email, $0) }
            }
        }

        progressSummaries = summaries
        recentActivity = activity.sorted { a, b in
            (a.progress.completedAt ?? .distantPast) > (b.progress.completedAt ?? .distantPast)
        }
        isLoading = false
    }
}

// MARK: - Inline Pending Rec Card

private struct InlinePendingRecCard: View {
    let rec: Recommendation
    let reviewerProfile: UserProfile
    let onDone: () async -> Void

    @State private var isActing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: rec.type.icon)
                    .foregroundStyle(.orange)
                Text(rec.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                Spacer()
            }
            Text(rec.rationale)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 10) {
                Button {
                    Task {
                        isActing = true
                        try? await FirestoreService.shared.updateRecommendationStatus(
                            id: rec.id, status: .rejected, reviewedBy: reviewerProfile.id)
                        await onDone()
                    }
                } label: {
                    Text("Reject")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    Task {
                        isActing = true
                        try? await FirestoreService.shared.updateRecommendationStatus(
                            id: rec.id, status: .approved, reviewedBy: reviewerProfile.id)
                        await onDone()
                    }
                } label: {
                    Text("Approve")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .disabled(isActing)
        }
        .padding(14)
        .background(Color.orange.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.25), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Navigation Destinations

private struct ParentReportsDestination: View {
    let confirmedStudents: [StudentAdultLink]
    var body: some View {
        if confirmedStudents.count == 1, let s = confirmedStudents.first {
            ReportDetailView(studentId: s.studentId, studentName: s.studentEmail)
        } else {
            List(confirmedStudents) { link in
                NavigationLink(link.studentEmail) {
                    ReportDetailView(studentId: link.studentId, studentName: link.studentEmail)
                }
            }
            .navigationTitle("Reports")
        }
    }
}

private struct ParentProgressDestination: View {
    let confirmedStudents: [StudentAdultLink]
    var body: some View {
        if confirmedStudents.count == 1, let s = confirmedStudents.first {
            StudentProgressDetailView(studentId: s.studentId, studentEmail: s.studentEmail)
        } else {
            List(confirmedStudents) { link in
                NavigationLink(link.studentEmail) {
                    StudentProgressDetailView(studentId: link.studentId, studentEmail: link.studentEmail)
                }
            }
            .navigationTitle("Progress")
        }
    }
}

// MARK: - Stat Card

private struct ParentStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    var highlight = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.title2.bold()).foregroundStyle(highlight ? color : .primary)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(highlight ? color.opacity(0.08) : Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(highlight ? color.opacity(0.3) : Color.clear, lineWidth: 1.5))
    }
}

// MARK: - Action Tile

private struct ParentActionTile: View {
    let icon: String
    let label: String
    let color: Color
    var badge: String? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2).foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(label).font(.caption.bold()).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if let badge {
                Text(badge).font(.caption2.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.red).clipShape(Capsule())
                    .offset(x: -8, y: 8)
            }
        }
    }
}

// MARK: - Empty State

private struct ParentEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.2.and.child.holdinghands")
                .font(.system(size: 40)).foregroundStyle(.tertiary)
            Text("No linked students yet.")
                .font(.subheadline.bold())
            Text("Go to Settings → Link Child to connect your child's account.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Linked Student Card (kept from prior version)

private struct LinkedStudentCard: View {
    let link: StudentAdultLink
    let summary: (completed: Int, total: Int)?

    private var fraction: Double {
        guard let s = summary, s.total > 0 else { return 0 }
        return Double(s.completed) / Double(s.total)
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(link.studentEmail.prefix(1)).uppercased())
                        .font(.title3.bold()).foregroundStyle(.blue)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(link.studentEmail).font(.subheadline.bold()).lineLimit(1)
                if let s = summary, s.total > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.blue.opacity(0.12)).frame(height: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(fraction == 1.0 ? Color.green : Color.blue)
                                .frame(width: geo.size.width * fraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                    Text("\(s.completed) of \(s.total) lessons done").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("No paths assigned yet").font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(summary.map { s in s.total > 0 ? "\(Int(fraction * 100))%" : "—" } ?? "—")
                    .font(.headline.bold()).foregroundStyle(.blue)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
