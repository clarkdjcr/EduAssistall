#if DEBUG
import SwiftUI

// Shown when the app is launched with --screenshots. No Firebase. No auth. Pure mock UI.
struct ScreenshotModeView: View {
    var body: some View {
        TabView {
            SS_CompanionView()
                .tabItem { Label("Companion", systemImage: "bubble.left.fill") }
                .accessibilityIdentifier("tab_companion")
            SS_DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .accessibilityIdentifier("tab_dashboard")
            SS_GoalsView()
                .tabItem { Label("Goals", systemImage: "target") }
                .accessibilityIdentifier("tab_goals")
            SS_TeacherView()
                .tabItem { Label("Monitor", systemImage: "person.2.fill") }
                .accessibilityIdentifier("tab_monitor")
            SS_ModePickerView()
                .tabItem { Label("Modes", systemImage: "dial.medium") }
                .accessibilityIdentifier("tab_modes")
        }
    }
}

// MARK: - Screen 1: AI Companion

private struct SS_CompanionView: View {
    private let messages: [ChatMessage] = [
        ChatMessage(role: .user, text: "Can you help me understand photosynthesis?"),
        ChatMessage(role: .assistant, text: "Of course! Let's think it through together. Where do you think plants get their energy from?"),
        ChatMessage(role: .user, text: "From sunlight?"),
        ChatMessage(role: .assistant, text: "Exactly right — sunlight is the energy source. That's the *photo* part. Plants use that energy to turn CO₂ from the air and water from the soil into glucose. The *synthesis* part. Can you put those two ideas together in your own words?"),
        ChatMessage(role: .user, text: "So plants make food using sunlight, air, and water?"),
        ChatMessage(role: .assistant, text: "**Perfect.** That's photosynthesis in a nutshell — and you built that understanding yourself. Write it down in your notes and see if it sticks!"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles").font(.caption2)
                    Text("AI-powered · Conversations visible to your teachers and parents").font(.caption2)
                    Spacer()
                    Text("Learn more").font(.caption2.bold()).underline()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(Color.appSecondaryGroupedBackground)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in SS_ChatBubble(message: msg) }
                        Color.clear.frame(height: 4)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                }

                Divider()

                HStack(spacing: 10) {
                    Text("Ask anything...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appSecondaryGroupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32)).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.appGroupedBackground)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("AI Companion")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .adaptiveTrailing) {
                    Label("Guided Discovery", systemImage: "dial.medium").labelStyle(.iconOnly)
                }
            }
        }
        .accessibilityIdentifier("screen_companion")
    }
}

private struct SS_ChatBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    private var attributed: AttributedString {
        (try? AttributedString(
            markdown: message.text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(message.text)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }
            if !isUser {
                Image(systemName: "brain.filled.head.profile")
                    .font(.caption).foregroundStyle(.blue)
                    .frame(width: 28, height: 28)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            Group {
                if isUser { Text(message.text) } else { Text(attributed) }
            }
            .font(.body)
            .foregroundStyle(isUser ? Color.white : Color.primary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(isUser ? Color.blue : Color.appSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            if isUser {
                Image(systemName: "person.circle.fill")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            if !isUser { Spacer(minLength: 48) }
        }
    }
}

// MARK: - Screen 2: Student Dashboard

private struct SS_DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good morning,").font(.subheadline).foregroundStyle(.secondary)
                        Text("Alex Rivera").font(.largeTitle.bold())
                    }
                    .padding(.horizontal, 20).padding(.top, 8)

                    HStack(spacing: 12) {
                        SS_StatCard(value: "7",   label: "Day Streak",    icon: "flame.fill",                  color: .orange)
                        SS_StatCard(value: "85%", label: "This Week",     icon: "chart.line.uptrend.xyaxis",   color: .green)
                        SS_StatCard(value: "12",  label: "Lessons Done",  icon: "checkmark.circle.fill",       color: .blue)
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 14) {
                        Image(systemName: "eye.fill").font(.title2).foregroundStyle(.purple)
                            .frame(width: 44, height: 44)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Learning Style").font(.caption).foregroundStyle(.secondary)
                            Text("Visual Learner").font(.headline)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Continue Learning").font(.headline).foregroundStyle(.white)
                            Text("Introduction to Fractions").font(.caption).foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill").font(.title2).foregroundStyle(.white.opacity(0.9))
                    }
                    .padding()
                    .background(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Interests").font(.headline).padding(.horizontal, 20)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["Mathematics", "Science", "History", "Astronomy", "Creative Writing"], id: \.self) { tag in
                                    Text(tag).font(.subheadline)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1)).foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Goals").font(.headline).foregroundStyle(.white)
                            Text("Set and track your learning goals").font(.caption).foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "target").font(.title2).foregroundStyle(.white.opacity(0.9))
                    }
                    .padding()
                    .background(LinearGradient(colors: [.indigo, .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Learning Journal").font(.headline).foregroundStyle(.white)
                            Text("Auto-generated summaries of your sessions").font(.caption).foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "book.closed.fill").font(.title2).foregroundStyle(.white.opacity(0.9))
                    }
                    .padding()
                    .background(LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    Spacer(minLength: 32)
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Dashboard")
            .inlineNavigationTitle()
        }
        .accessibilityIdentifier("screen_dashboard")
    }
}

private struct SS_StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.title2.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Screen 3: Learning Goals

private struct SS_GoalsView: View {
    private let inProgress: [LearningGoal] = {
        var g1 = LearningGoal(
            studentId: "demo", title: "Master fractions and decimals",
            notes: "Focus on multiplying and dividing fractions", subject: "Math",
            targetDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())
        )
        var g2 = LearningGoal(
            studentId: "demo", title: "Finish the Ecosystems learning path",
            notes: "Complete all 8 modules before the unit test", subject: "Science",
            targetDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
        )
        var g3 = LearningGoal(
            studentId: "demo", title: "Write a 5-paragraph essay",
            notes: "Practice introduction, body, and conclusion structure", subject: "ELA"
        )
        return [g1, g2, g3]
    }()

    private let completed: [LearningGoal] = {
        var g = LearningGoal(studentId: "demo", title: "Learn the US state capitals", subject: "Social Studies")
        g.status = .completed
        return [g]
    }()

    var body: some View {
        NavigationStack {
            List {
                Section("In Progress") {
                    ForEach(inProgress) { goal in SS_GoalRow(goal: goal) }
                }
                Section("Completed") {
                    ForEach(completed) { goal in SS_GoalRow(goal: goal) }
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .background(Color.appGroupedBackground)
            .navigationTitle("My Goals")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Image(systemName: "plus")
                }
            }
        }
        .accessibilityIdentifier("screen_goals")
    }
}

private struct SS_GoalRow: View {
    let goal: LearningGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: goal.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(goal.status == .completed ? Color.green : Color.blue)
                Text(goal.title).font(.subheadline.bold()).lineLimit(2)
            }
            if let subject = goal.subject {
                Text(subject).font(.caption).foregroundStyle(.secondary).padding(.leading, 26)
            }
            if let target = goal.targetDate {
                Text("Due \(target, style: .relative)")
                    .font(.caption2).foregroundStyle(.tertiary).padding(.leading, 26)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Screen 4: Teacher Monitor

private struct SS_MockStudent: Identifiable {
    let id: String
    let name: String
    let isActive: Bool
    let isLocked: Bool
    let completed: Int
    let total: Int
    let subject: String?
}

private struct SS_TeacherView: View {
    private let students: [SS_MockStudent] = [
        SS_MockStudent(id: "1", name: "Alex Rivera",   isActive: true,  isLocked: false, completed: 7,  total: 10, subject: "Fractions"),
        SS_MockStudent(id: "2", name: "Jordan Lee",    isActive: true,  isLocked: false, completed: 4,  total: 10, subject: "Ecosystems"),
        SS_MockStudent(id: "3", name: "Sam Patel",     isActive: false, isLocked: true,  completed: 2,  total: 10, subject: nil),
        SS_MockStudent(id: "4", name: "Morgan Chen",   isActive: false, isLocked: false, completed: 9,  total: 10, subject: nil),
        SS_MockStudent(id: "5", name: "Taylor Brooks", isActive: true,  isLocked: false, completed: 5,  total: 10, subject: "US History"),
    ]

    var body: some View {
        NavigationStack {
            List(students) { s in
                SS_MonitorRow(student: s)
            }
            .navigationTitle("Monitor")
            .inlineNavigationTitle()
        }
        .accessibilityIdentifier("screen_monitor")
    }
}

private struct SS_MonitorRow: View {
    let student: SS_MockStudent

    var statusColor: Color {
        if student.isLocked  { return .orange }
        if student.isActive  { return .green }
        return .secondary
    }

    var statusLabel: String {
        if student.isLocked { return "Paused" }
        if student.isActive { return "Active now" }
        return "Offline"
    }

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(student.name.prefix(1)))
                        .font(.headline.bold()).foregroundStyle(.blue)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(student.name).font(.subheadline.bold())
                HStack(spacing: 4) {
                    Circle().fill(statusColor).frame(width: 7, height: 7)
                    Text(statusLabel).font(.caption).foregroundStyle(.secondary)
                    if let subject = student.subject {
                        Text("· \(subject)").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                ProgressView(value: Double(student.completed), total: Double(student.total))
                    .tint(.blue)
                    .frame(maxWidth: 180)
            }

            Spacer()

            Text("\(student.completed)/\(student.total)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Screen 5: Mode Picker

private struct SS_ModePickerView: View {
    @State private var selectedMode: InteractionMode = .guidedDiscovery

    private func icon(for mode: InteractionMode) -> String {
        switch mode {
        case .guidedDiscovery:    return "magnifyingglass"
        case .coCreation:         return "person.2.fill"
        case .reflectiveCoaching: return "brain.head.profile"
        case .silentSupport:      return "ear"
        }
    }

    var body: some View {
        NavigationStack {
            List(InteractionMode.allCases) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: icon(for: mode))
                            .foregroundStyle(.blue).frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.displayName).font(.subheadline.bold()).foregroundStyle(.primary)
                            Text(mode.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if mode == selectedMode {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
            .navigationTitle("Learning Mode")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .adaptiveTrailing) {
                    Button("Done") {}
                }
            }
        }
        .accessibilityIdentifier("screen_modes")
    }
}
#endif
