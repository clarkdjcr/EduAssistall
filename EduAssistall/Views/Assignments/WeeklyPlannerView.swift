import SwiftUI

struct WeeklyPlannerView: View {
    let profile: UserProfile

    @State private var currentWeek = WeeklyAssignment.mondayOf(week: Date())
    @State private var assignments: [WeeklyAssignment] = []
    @State private var archivedWeeks: [[WeeklyAssignment]] = []
    @State private var isLoading = true
    @State private var isArchiving = false
    @State private var showArchive = false
    @State private var loadError: Error?

    private var byDay: [Int: WeeklyAssignment] {
        Dictionary(assignments.map { ($0.dayNumber, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var allDone: Bool { !assignments.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            weekNavigator

                            if let err = loadError {
                                Label("Could not load: \(err.localizedDescription)",
                                      systemImage: "exclamationmark.triangle")
                                .font(.caption).foregroundStyle(.orange)
                                .padding(.horizontal, 20)
                            }

                            if assignments.isEmpty {
                                EmptyWeekCard()
                                    .padding(.horizontal, 20)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { day in
                                        if let assignment = byDay[day] {
                                            NavigationLink {
                                                AssignmentDetailView(
                                                    assignment: assignment,
                                                    profile: profile
                                                )
                                            } label: {
                                                DayAssignmentCard(assignment: assignment)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            EmptyDayCard(dayNumber: day)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                                if allDone {
                                    archiveButton
                                        .padding(.horizontal, 20)
                                }
                            }

                            Spacer(minLength: 32)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Weekly Planner")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showArchive = true } label: {
                        Image(systemName: "archivebox")
                    }
                }
            }
            .sheet(isPresented: $showArchive) {
                ArchivedWeeksView(studentId: profile.id)
            }
            .task(id: currentWeek) { await load() }
        }
    }

    // MARK: - Week navigation bar

    private var weekNavigator: some View {
        HStack {
            Button {
                currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: currentWeek)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.blue)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(weekRangeLabel)
                    .font(.headline)
                Text(isCurrentWeek ? "This Week" : "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                currentWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentWeek)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 20)
    }

    private var archiveButton: some View {
        Button {
            Task { await archiveWeek() }
        } label: {
            HStack {
                Spacer()
                if isArchiving {
                    ProgressView().tint(.white)
                } else {
                    Label("Archive This Week", systemImage: "archivebox.fill")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                }
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isArchiving)
    }

    // MARK: - Helpers

    private var weekRangeLabel: String {
        let end = Calendar.current.date(byAdding: .day, value: 4, to: currentWeek)!
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: currentWeek)) – \(fmt.string(from: end))"
    }

    private var isCurrentWeek: Bool {
        WeeklyAssignment.mondayOf(week: Date()) == currentWeek
    }

    private func load() async {
        isLoading = true
        loadError = nil
        do {
            assignments = try await FirestoreService.shared.fetchWeeklyAssignments(
                studentId: profile.id, weekOf: currentWeek
            )
        } catch {
            loadError = error
        }
        isLoading = false
    }

    private func archiveWeek() async {
        isArchiving = true
        try? await FirestoreService.shared.archiveWeek(studentId: profile.id, weekOf: currentWeek)
        assignments = []
        isArchiving = false
    }
}

// MARK: - Day Assignment Card

private struct DayAssignmentCard: View {
    let assignment: WeeklyAssignment

    private var dayColor: Color {
        switch assignment.dayNumber {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .purple
        default: return .red
        }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(assignment.scheduledDate)
    }

    private var borderColor: Color {
        if assignment.isPast { return .red }
        if isToday { return .orange }
        return dayColor
    }

    @ViewBuilder
    private var dueBadge: some View {
        if assignment.isPast {
            Label("Overdue", systemImage: "exclamationmark.circle.fill")
                .font(.caption2.bold())
                .foregroundStyle(.red)
        } else if isToday {
            Label("Due Today", systemImage: "clock.fill")
                .font(.caption2.bold())
                .foregroundStyle(.orange)
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(assignment.dayLabel.prefix(3))
                    .font(.caption2.bold())
                    .foregroundStyle(dayColor)
                Text("\(Calendar.current.component(.day, from: assignment.scheduledDate))")
                    .font(.title3.bold())
                    .foregroundStyle(dayColor)
            }
            .frame(width: 44)

            Rectangle()
                .fill(dayColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Label(assignment.teacherName, systemImage: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                dueBadge
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(borderColor.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Empty Day Card

private struct EmptyDayCard: View {
    let dayNumber: Int

    private var label: String {
        switch dayNumber {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        default: return "Friday"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(label.prefix(3))
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .frame(width: 44)

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 3)
                .clipShape(Capsule())

            Text("No assignment")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Empty Week Card

private struct EmptyWeekCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No Assignments This Week")
                .font(.headline)
            Text("Your teacher hasn't assigned work for this week yet.\nCheck back soon.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Archived Weeks Sheet

struct ArchivedWeeksView: View {
    let studentId: String

    @State private var archived: [WeeklyAssignment] = []
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    private var groupedByWeek: [(Date, [WeeklyAssignment])] {
        let grouped = Dictionary(grouping: archived) { $0.weekOf }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if archived.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 44))
                            .foregroundStyle(.tertiary)
                        Text("No Archived Weeks")
                            .font(.headline)
                        Text("Completed weeks will appear here after you archive them.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedByWeek, id: \.0) { week, days in
                            Section(weekLabel(week)) {
                                ForEach(days.sorted { $0.dayNumber < $1.dayNumber }) { a in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(a.dayLabel)
                                            .font(.caption.bold())
                                            .foregroundStyle(.secondary)
                                        Text(a.title)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                    }
                                    .padding(.vertical, 4)
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
            .navigationTitle("Archived Weeks")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: adaptiveTopBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                archived = (try? await FirestoreService.shared.fetchArchivedWeeklyAssignments(studentId: studentId)) ?? []
                isLoading = false
            }
        }
    }

    private func weekLabel(_ monday: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        let fri = Calendar.current.date(byAdding: .day, value: 4, to: monday)!
        return "Week of \(fmt.string(from: monday)) – \(fmt.string(from: fri))"
    }
}
