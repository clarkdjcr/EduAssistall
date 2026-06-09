import SwiftUI

struct SchoolOverviewView: View {
    let adminProfile: UserProfile

    @State private var teachers: [UserProfile] = []
    @State private var totalStudents = 0
    @State private var isLoading = true

    private var districtId: String { adminProfile.districtId ?? "" }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            statsRow
                            teacherSummaryCard
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("School Overview")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(teachers.count)", label: "Teachers",
                     icon: "person.fill.checkmark", color: .blue)
            StatCard(value: "\(totalStudents)", label: "Students",
                     icon: "person.3.fill", color: .green)
            StatCard(value: districtId.isEmpty ? "—" : districtId,
                     label: "District ID", icon: "building.2", color: .purple)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Teacher Summary Card

    private var teacherSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teachers")
                .font(.headline)
                .padding(.horizontal, 20)

            if teachers.isEmpty {
                Text("No teachers found for this district.\nMake sure teachers have been assigned districtId \"\(districtId)\" in their profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(20)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(teachers) { teacher in
                        NavigationLink {
                            TeacherAdminDetailView(teacher: teacher)
                        } label: {
                            TeacherSummaryRow(teacher: teacher)
                        }
                        .buttonStyle(.plain)
                        if teacher.id != teachers.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(Color.appSecondaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Load

    private func load() async {
        guard !districtId.isEmpty else { isLoading = false; return }
        isLoading = true
        teachers = (try? await FirestoreService.shared.fetchTeachers(districtId: districtId)) ?? []
        // Fetch all rosters in parallel to sum student counts
        var count = 0
        await withTaskGroup(of: Int.self) { group in
            for teacher in teachers {
                group.addTask {
                    let links = (try? await FirestoreService.shared.fetchLinkedStudents(adultId: teacher.id)) ?? []
                    return links.filter(\.confirmed).count
                }
            }
            for await n in group { count += n }
        }
        totalStudents = count
        isLoading = false
    }
}

// MARK: - Subviews

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct TeacherSummaryRow: View {
    let teacher: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 38, height: 38)
                .overlay(
                    Text(teacher.displayName.prefix(1).uppercased())
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(teacher.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(teacher.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
