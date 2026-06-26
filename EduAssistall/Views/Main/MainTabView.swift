import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var connectivity = ConnectivityService.shared
    @State private var showBackOnlineToast = false
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
                AdminTabView(profile: profile)
            }

            if !connectivity.isOnline {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }

            if showBackOnlineToast {
                BackOnlineToast()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: connectivity.isOnline)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showBackOnlineToast)
        .onChange(of: connectivity.isOnline) { wasOnline, isNowOnline in
            guard !wasOnline && isNowOnline else { return }
            showBackOnlineToast = true
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation { showBackOnlineToast = false }
            }
        }
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
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .symbolEffect(.pulse)
                .font(.callout)

            VStack(alignment: .leading, spacing: 1) {
                Text("You're Offline")
                    .font(.caption.bold())
                Text("Learning paths and progress available from your last sync")
                    .font(.caption2)
                    .opacity(0.85)
            }

            Spacer()
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(red: 0.22, green: 0.32, blue: 0.52))
    }
}

// MARK: - Back Online Toast

private struct BackOnlineToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi")
                .font(.caption.bold())
            Text("Back online")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
        .background(Color.green.opacity(0.92))
        .clipShape(Capsule())
        .shadow(color: .green.opacity(0.25), radius: 8, y: 4)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 12)
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

            WeeklyPlannerView(profile: profile)
                .tabItem {
                    Label("Assignments", systemImage: "calendar.badge.checkmark")
                }

            CompanionView(profile: profile)
                .tabItem {
                    Label("Companion", systemImage: "bubble.left.and.bubble.right.fill")
                }

            StudentProgressView(profile: profile)
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }

            // Phase 4: Quests tab
            QuestsView(profile: profile)
                .tabItem {
                    Label("Quests", systemImage: "flag.fill")
                }

            // Phase 4: Recommendations tab
            RecommendationsView(profile: profile, learningProfile: nil)
                .tabItem {
                    Label("For You", systemImage: "sparkles")
                }

            ProfileSettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
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

            TeacherAssistView(teacherProfile: profile)
                .tabItem {
                    Label("Assist", systemImage: "wand.and.stars")
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
    @State private var showAssignWeek               = false

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

                Section("Assignments") {
                    NavigationLink {
                        DailyLessonPlansView(teacherProfile: profile)
                    } label: {
                        Label("Daily Lesson Plans", systemImage: "list.bullet.clipboard.fill")
                    }

                    Button { showAssignWeek = true } label: {
                        Label("Assign to Students", systemImage: "calendar.badge.plus")
                            .foregroundStyle(.primary)
                    }
                }

                Section("Grading") {
                    NavigationLink {
                        GradingSetupView(teacherProfile: profile)
                    } label: {
                        Label("Grading Setup", systemImage: "percent")
                    }
                }

                Section("Curriculum") {
                    NavigationLink {
                        CurriculumLibraryView(profile: profile)
                    } label: {
                        Label("Curriculum Library", systemImage: "archivebox.fill")
                    }
                }

                Section("Teaching Knowledge") {
                    NavigationLink {
                        TeacherJournalView(teacherProfile: profile)
                    } label: {
                        Label("Teaching Journal", systemImage: "note.text")
                    }

                    NavigationLink {
                        TeacherWikiView(teacherProfile: profile)
                    } label: {
                        Label("Teaching Wiki", systemImage: "book.fill")
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
                    .macSheetFrame(width: 1100, height: 780)
            }
            .sheet(isPresented: $showParentLetter) {
                GenerateParentLetterView(teacherProfile: profile)
                    .macSheetFrame(width: 860, height: 700)
            }
            .sheet(isPresented: $showAssignWeek) {
                AssignWeekView(teacherProfile: profile)
                    .macSheetFrame(width: 680, height: 580)
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

struct ProfileSettingsView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let profile = authVM.currentProfile {
                        HStack(spacing: 14) {
                            // Phase 2: Avatar display in profile
                            if let avatarConfig = profile.avatarConfig {
                                AvatarPreviewView(config: avatarConfig)
                                    .frame(width: 56, height: 56)
                            } else {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(profile.displayName.prefix(1).uppercased())
                                            .font(.title2.bold())
                                            .foregroundStyle(.blue)
                                    )
                            }
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

                // Phase 2: Avatar customization (students only)
                if let profile = authVM.currentProfile, profile.role == .student {
                    Section {
                        NavigationLink {
                            AvatarCustomizationView()
                        } label: {
                            Label("Customize Avatar", systemImage: "person.crop.circle")
                        }
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

                    // Phase 1: Sound effects toggle (students only)
                    if let profile = authVM.currentProfile, profile.role == .student {
                        Toggle("Sound Effects", isOn: Binding(
                            get: { profile.soundEffectsEnabled },
                            set: { newValue in
                                Task {
                                    var updatedProfile = profile
                                    updatedProfile.soundEffectsEnabled = newValue
                                    try? await FirestoreService.shared.updateUserProfile(updatedProfile)
                                }
                            }
                        ))
                        .tint(.blue)
                    }

                    // Phase 1: Haptic feedback toggle (students only)
                    if let profile = authVM.currentProfile, profile.role == .student {
                        Toggle("Haptic Feedback", isOn: Binding(
                            get: { profile.hapticFeedbackEnabled },
                            set: { newValue in
                                Task {
                                    var updatedProfile = profile
                                    updatedProfile.hapticFeedbackEnabled = newValue
                                    try? await FirestoreService.shared.updateUserProfile(updatedProfile)
                                }
                            }
                        ))
                        .tint(.blue)
                    }

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

                    // IT Admin integration dashboard (SharePoint + Firebase secrets)
                    if let profile = authVM.currentProfile,
                       profile.role == .teacher || profile.role == .admin {
                        NavigationLink {
                            ITAdminSetupView(profile: profile)
                        } label: {
                            Label("IT Integration", systemImage: "server.rack")
                        }
                    }

                    // Curriculum library — teachers and admins can upload curriculum + grounding content
                    if let profile = authVM.currentProfile,
                       profile.role == .teacher || profile.role == .admin {
                        NavigationLink {
                            CurriculumLibraryView(profile: profile)
                        } label: {
                            Label("Curriculum Library", systemImage: "archivebox.fill")
                        }
                    }

                    // Documents awaiting teacher approval (Firebase backend)
                    if let profile = authVM.currentProfile,
                       profile.role == .teacher || profile.role == .admin {
                        NavigationLink {
                            DocumentsApprovalView(teacherProfile: profile)
                        } label: {
                            Label("Documents Approval", systemImage: "checkmark.seal")
                        }
                    }

                    if let profile = authVM.currentProfile, profile.role == .admin {
                        NavigationLink {
                            StandardsUpdateReviewView()
                        } label: {
                            Label("Standards Updates", systemImage: "arrow.triangle.2.circlepath.doc.on.clipboard")
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

                if let profile = authVM.currentProfile, profile.role == .parent {
                    Section {
                        NavigationLink {
                            LinkChildSettingsView(adultId: profile.id)
                        } label: {
                            Label("Link Child", systemImage: "figure.2.and.child.holdinghands")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task { @MainActor in authVM.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityIdentifier("sign_out_button")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Link Child Settings (parents only)

private struct LinkChildSettingsView: View {
    let adultId: String
    @Environment(\.dismiss) private var dismiss
    @State private var studentEmail = ""
    @State private var isLinking = false
    @State private var result: LinkResult?

    enum LinkResult { case success(String); case failure(String) }

    var body: some View {
        Form {
            Section {
                TextField("Child's email address", text: $studentEmail)
                    .emailInput()
            } footer: {
                Text("EduAssist will link only to an existing student account. Ask your child's teacher if the student has not been invited yet.")
            }

            if let result {
                Section {
                    switch result {
                    case .success(let name):
                        Label("Linked to \(name). They now appear on your dashboard.",
                              systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failure(let msg):
                        Label(msg, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                Button {
                    Task { await link() }
                } label: {
                    HStack {
                        Spacer()
                        if isLinking { ProgressView() } else { Text("Link Child Account").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .disabled(studentEmail.trimmingCharacters(in: .whitespaces).isEmpty || isLinking)
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .background(Color.appGroupedBackground)
        .navigationTitle("Link Child")
        .inlineNavigationTitle()
    }

    private func link() async {
        isLinking = true
        result = nil
        let email = studentEmail.trimmingCharacters(in: .whitespaces).lowercased()
        do {
            let r = try await CloudFunctionService.shared.lookupStudentByEmail(email)
            let newLink = StudentAdultLink(studentId: r.studentId, adultId: adultId,
                                          adultRole: .parent, studentEmail: email)
            try await FirestoreService.shared.createStudentAdultLink(newLink)
            result = .success(r.displayName)
            try? await Task.sleep(for: .seconds(1.5))
            dismiss()
        } catch let error as NSError where error.domain == "com.firebase.functions" {
            result = .failure(error.localizedDescription)
        } catch {
            result = .failure("Something went wrong. Please try again.")
        }
        isLinking = false
    }
}
