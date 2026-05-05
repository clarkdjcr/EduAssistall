import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var connectivity = ConnectivityService.shared
    let profile: UserProfile

    var body: some View {
        ZStack(alignment: .top) {
            switch profile.role {
            case .student:
                StudentTabView(profile: profile)
            case .teacher:
                TeacherTabView(profile: profile)
            case .parent:
                ParentTabView(profile: profile)
            case .admin:
                TeacherTabView(profile: profile)
            }

            if !connectivity.isOnline {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: connectivity.isOnline)
        #if os(iOS)
        .task {
            await NotificationService.shared.requestPermission()
        }
        #endif
    }
}

// MARK: - Offline Banner

private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("You're offline — showing cached content")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.orange)
    }
}

// MARK: - Student Tabs

private struct StudentTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            StudentDashboardView(profile: profile)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            LearningPathsView(profile: profile)
                .tabItem {
                    Label("Learning", systemImage: "book.fill")
                }

            CompanionView(profile: profile)
                .tabItem {
                    Label("Companion", systemImage: "bubble.left.and.bubble.right.fill")
                }

            CareerExplorerView(profile: profile)
                .tabItem {
                    Label("Careers", systemImage: "briefcase.fill")
                }

            StudentProgressView(profile: profile)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
    }
}

// MARK: - Teacher Tabs

private struct TeacherTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            TeacherDashboardView(profile: profile)
                .tabItem {
                    Label("Roster", systemImage: "person.3.fill")
                }

            TeacherMonitorView(teacherProfile: profile)
                .tabItem {
                    Label("Monitor", systemImage: "eye.fill")
                }

            TeacherDocumentsTabView(profile: profile)
                .tabItem {
                    Label("Create", systemImage: "sparkles")
                }

            MessagesListView(profile: profile)
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }

            ProfileSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

// MARK: - Teacher Documents Tab (FR-T5, FR-T6)

private struct TeacherDocumentsTabView: View {
    let profile: UserProfile

    @State private var studentIds: [String]         = []
    @State private var showLessonPlan               = false
    @State private var showParentLetter             = false

    var body: some View {
        NavigationStack {
            List {
                Section("AI Generate") {
                    Button {
                        showLessonPlan = true
                    } label: {
                        Label("Lesson Plan", systemImage: "doc.text.fill")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        showParentLetter = true
                    } label: {
                        Label("Parent Letter", systemImage: "envelope.fill")
                            .foregroundStyle(.primary)
                    }
                }

                Section("Pending Reviews") {
                    NavigationLink {
                        PendingRecommendationsView(reviewerProfile: profile, studentIds: studentIds)
                    } label: {
                        Label("AI Recommendations", systemImage: "checkmark.shield.fill")
                    }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .background(Color.appGroupedBackground)
            .navigationTitle("Create")
            .inlineNavigationTitle()
            .sheet(isPresented: $showLessonPlan) {
                GenerateLessonPlanView(teacherProfile: profile)
            }
            .sheet(isPresented: $showParentLetter) {
                GenerateParentLetterView(teacherProfile: profile)
            }
        }
        .task {
            let links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: profile.id)) ?? []
            studentIds = links.filter(\.confirmed).map(\.studentId)
        }
    }
}

// MARK: - Parent Tabs

private struct ParentTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            ParentDashboardView(profile: profile)
                .tabItem {
                    Label("Overview", systemImage: "house.fill")
                }

            ParentReportsTabView(profile: profile)
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }

            MessagesListView(profile: profile)
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }

            ProfileSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

// MARK: - Parent Reports Tab

private struct ParentReportsTabView: View {
    let profile: UserProfile
    @State private var children: [(studentId: String, name: String)] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if children.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No Reports Yet")
                            .font(.title3.bold())
                        Text("Link a student to see their progress reports.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if children.count == 1, let child = children.first {
                    ReportDetailView(studentId: child.studentId, studentName: child.name)
                } else {
                    List(children, id: \.studentId) { child in
                        NavigationLink {
                            ReportDetailView(studentId: child.studentId, studentName: child.name)
                        } label: {
                            Label(child.name, systemImage: "person.fill")
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
            .navigationTitle("Reports")
            .inlineNavigationTitle()
        }
        .task { await loadChildren() }
    }

    private func loadChildren() async {
        isLoading = true
        let links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: profile.id))?.filter(\.confirmed) ?? []
        var result: [(String, String)] = []
        for link in links {
            let name = (try? await FirestoreService.shared.fetchUserProfile(uid: link.studentId))?.displayName ?? "Student"
            result.append((link.studentId, name))
        }
        children = result
        isLoading = false
    }
}

// MARK: - Placeholder (Phase 2+ screens)

struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2.bold())
            Text("Coming in Phase 2")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appGroupedBackground)
        .navigationTitle(title)
    }
}

// MARK: - Profile & Settings

private struct ProfileSettingsView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let profile = authVM.currentProfile {
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
                                Text(profile.role.rawValue.capitalized)
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section {
                    NavigationLink {
                        DataPrivacyView()
                    } label: {
                        Label("Privacy & Data", systemImage: "lock.shield")
                    }
                    .accessibilityLabel("Privacy and data settings")

                    // NFR-005: accessibility preferences
                    NavigationLink {
                        AccessibilitySettingsView()
                    } label: {
                        Label("Accessibility", systemImage: "accessibility")
                    }
                    .accessibilityLabel("Accessibility settings")

                    // FR-203: Classroom configuration — visible to teachers
                    if let profile = authVM.currentProfile, profile.role == .teacher {
                        NavigationLink {
                            ClassroomConfigView(teacherProfile: profile)
                        } label: {
                            Label("Classroom Config", systemImage: "slider.horizontal.3")
                        }
                    }

                    // FR-105: Topic boundaries — visible to teachers and admins who have a districtId
                    if let profile = authVM.currentProfile,
                       (profile.role == .teacher || profile.role == .admin),
                       let districtId = profile.districtId {
                        NavigationLink {
                            TopicBoundariesView(districtId: districtId)
                        } label: {
                            Label("Topic Boundaries", systemImage: "shield.lefthalf.filled")
                        }
                    }

                    // Admin setup — visible to teachers and admins
                    if let profile = authVM.currentProfile,
                       profile.role == .teacher || profile.role == .admin {
                        NavigationLink {
                            SchoolAdminSetupView(profile: profile)
                        } label: {
                            Label("Admin Setup", systemImage: "building.2")
                        }
                    }

                    // FR-G5: AI usage dashboard — admins and teachers only
                    if let profile = authVM.currentProfile,
                       profile.role == .teacher || profile.role == .admin {
                        NavigationLink {
                            AIUsageDashboardView()
                        } label: {
                            Label("AI Usage", systemImage: "chart.bar.xaxis")
                        }
                    }

                    // FR-402: Data retention config — admins and teachers only
                    if let profile = authVM.currentProfile,
                       profile.role == .teacher || profile.role == .admin {
                        NavigationLink {
                            DataRetentionView(profile: profile)
                        } label: {
                            Label("Data Retention", systemImage: "clock.arrow.circlepath")
                        }
                    }

                    // FR-405: PII scan results — admins and teachers only
                    if let profile = authVM.currentProfile,
                       profile.role == .teacher || profile.role == .admin {
                        NavigationLink {
                            PIIScanResultsView()
                        } label: {
                            Label("PII Scan Results", systemImage: "magnifyingglass.circle")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
