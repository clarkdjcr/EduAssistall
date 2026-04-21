import SwiftUI
import FirebaseFirestore

struct TeacherMonitorView: View {
    let teacherProfile: UserProfile

    @State private var students: [StudentAdultLink] = []
    @State private var progressSummaries: [String: (completed: Int, total: Int)] = [:]
    @State private var lockStates: [String: Bool] = [:]
    @State private var activeSessions: [String: ActiveSession] = [:]  // FR-200
    @State private var sessionFlags: [String: [SessionFlag]] = [:]    // FR-201
    @State private var sessionListener: ListenerRegistration?
    @State private var flagListeners: [ListenerRegistration] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if students.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(students) { link in
                            NavigationLink {
                                StudentProgressDetailView(
                                    studentId: link.studentId,
                                    studentEmail: link.studentEmail
                                )
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        HStack {
                                            // FR-201: Alerts button when flags exist
                                            let flags = sessionFlags[link.studentId] ?? []
                                            if !flags.isEmpty {
                                                NavigationLink {
                                                    SessionAlertsView(
                                                        studentEmail: link.studentEmail,
                                                        flags: flags
                                                    )
                                                } label: {
                                                    Label("Alerts", systemImage: "bell.badge.fill")
                                                        .foregroundStyle(.red)
                                                }
                                            }
                                            // FR-200: live transcript button when session is active
                                            if activeSessions[link.studentId]?.isActive == true {
                                                NavigationLink {
                                                    ConversationTranscriptView(
                                                        studentId: link.studentId,
                                                        studentEmail: link.studentEmail,
                                                        teacherProfile: teacherProfile
                                                    )
                                                } label: {
                                                    Label("Live", systemImage: "eye.fill")
                                                        .foregroundStyle(.green)
                                                }
                                            }
                                            NavigationLink {
                                                StudentModeConfigView(
                                                    studentId: link.studentId,
                                                    studentEmail: link.studentEmail
                                                )
                                            } label: {
                                                Label("Modes", systemImage: "dial.medium")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                MonitorStudentRow(
                                    link: link,
                                    summary: progressSummaries[link.studentId],
                                    isLocked: lockStates[link.studentId] ?? false,
                                    isActive: activeSessions[link.studentId]?.isActive == true,
                                    activeSession: activeSessions[link.studentId],
                                    flags: sessionFlags[link.studentId] ?? []
                                ) {
                                    Task { await toggleLock(for: link) }
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
            .navigationTitle("Monitor")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
            .onDisappear {
                sessionListener?.remove()
                flagListeners.forEach { $0.remove() }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Students Yet")
                .font(.title3.bold())
            Text("Link students to your class to monitor their progress here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        let linked = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacherProfile.id)) ?? []
        students = linked.filter { $0.confirmed }

        // Fetch progress summaries for all students concurrently
        await withTaskGroup(of: (String, Int, Int).self) { group in
            for link in students {
                group.addTask {
                    async let fetchPaths = FirestoreService.shared.fetchAllLearningPaths(studentId: link.studentId)
                    async let fetchProgress = FirestoreService.shared.fetchAllProgress(studentId: link.studentId)

                    let paths = (try? await fetchPaths) ?? []
                    let progressList = (try? await fetchProgress) ?? []
                    let progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.contentItemId, $0) })

                    let allItems = paths.flatMap(\.items)
                    let total = allItems.count
                    let completed = allItems.filter { progressMap[$0.contentItemId]?.status == .completed }.count
                    return (link.studentId, completed, total)
                }
            }
            for await (studentId, completed, total) in group {
                progressSummaries[studentId] = (completed, total)
            }
        }

        isLoading = false

        // FR-200: start/restart live session listener with current student IDs
        sessionListener?.remove()
        let studentIds = students.map(\.studentId)
        if !studentIds.isEmpty {
            sessionListener = FirestoreService.shared.listenActiveSessions(studentIds: studentIds) { sessions in
                activeSessions = sessions
            }
        }

        // FR-201: start per-student flag listeners
        flagListeners.forEach { $0.remove() }
        flagListeners = students.map { link in
            FirestoreService.shared.listenSessionFlags(studentId: link.studentId) { flags in
                sessionFlags[link.studentId] = flags.filter { !$0.acknowledged }
            }
        }
    }

    // FR-106: toggle companion lock for a student
    private func toggleLock(for link: StudentAdultLink) async {
        let currentlyLocked = lockStates[link.studentId] ?? false
        lockStates[link.studentId] = !currentlyLocked
        do {
            try await FirestoreService.shared.setCompanionLock(
                studentId: link.studentId,
                locked: !currentlyLocked,
                by: teacherProfile,
                reason: currentlyLocked ? "Unlocked by educator" : "Locked by educator for review"
            )
        } catch {
            lockStates[link.studentId] = currentlyLocked  // revert on failure
        }
    }
}

// MARK: - Monitor Student Row

private struct MonitorStudentRow: View {
    let link: StudentAdultLink
    let summary: (completed: Int, total: Int)?
    var isLocked: Bool = false
    var isActive: Bool = false
    var activeSession: ActiveSession? = nil
    var flags: [SessionFlag] = []
    var onToggleLock: (() -> Void)? = nil

    private var fraction: Double {
        guard let s = summary, s.total > 0 else { return 0 }
        return Double(s.completed) / Double(s.total)
    }

    // FR-201: inactivity = active session with no message in 10+ min
    private var isInactive: Bool {
        guard isActive, let last = activeSession?.lastMessageAt else { return false }
        return Date().timeIntervalSince(last) > 600
    }

    // FR-201: highest-severity flag color for the badge
    private var badgeColor: Color {
        if flags.contains(where: { $0.type == .safety }) { return .red }
        if flags.contains(where: { $0.type == .frustration }) { return .orange }
        return .yellow
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(isLocked ? Color.orange.opacity(0.15) : Color.blue.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(link.studentEmail.prefix(1)).uppercased())
                        .font(.headline.bold())
                        .foregroundStyle(isLocked ? .orange : .blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(link.studentEmail)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    if isActive {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .accessibilityLabel("Active session")
                    }
                    if isInactive {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Inactive session")
                    }
                }

                if let s = summary {
                    Text("\(s.completed) of \(s.total) lessons done")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.blue.opacity(0.12))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(fraction == 1.0 ? Color.green : Color.blue)
                                .frame(width: geo.size.width * fraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                } else {
                    Text("No paths assigned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // FR-201: Alert flag badge
            if !flags.isEmpty {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(badgeColor)
                        .font(.system(size: 18))
                    Text("\(flags.count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(badgeColor)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
                .accessibilityLabel("\(flags.count) alerts for \(link.studentEmail)")
            }

            // FR-106: Kill switch button
            Button {
                onToggleLock?()
            } label: {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .foregroundStyle(isLocked ? .orange : .secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isLocked ? "Unlock companion for \(link.studentEmail)" : "Lock companion for \(link.studentEmail)")
        }
        .padding(.vertical, 4)
    }
}
