import SwiftUI

struct CareerDetailView: View {
    let career: CareerPath
    let luminaries: [Luminary]

    private var relatedLuminaries: [Luminary] {
        luminaries.filter { lum in
            lum.relatedInterests.contains { career.relatedInterests.map { $0.lowercased() }.contains($0.lowercased()) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Hero
                heroSection

                // Quick stats
                statsRow

                // Description
                Text(career.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)

                // Education paths
                educationSection

                // Luminaries
                if !relatedLuminaries.isEmpty {
                    relatedLuminariesSection
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 8)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle(career.title)
        .inlineNavigationTitle()
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(career.color.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: career.icon)
                    .font(.system(size: 30))
                    .foregroundStyle(career.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(career.title)
                    .font(.title2.bold())
                HStack(spacing: 6) {
                    ForEach(career.relatedInterests.prefix(3), id: \.self) { interest in
                        Text(interest)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(career.color.opacity(0.1))
                            .foregroundStyle(career.color)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBadge(
                icon: "dollarsign.circle.fill",
                label: "Avg. Salary",
                value: career.averageSalary,
                color: .green
            )
            StatBadge(
                icon: "arrow.up.right.circle.fill",
                label: "Job Growth",
                value: career.growthOutlook,
                color: .blue
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Education Paths

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Get There")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(career.educationOptions) { option in
                EducationCard(option: option)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Related Luminaries

    private var relatedLuminariesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inspiring People in This Field")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(relatedLuminaries.prefix(3)) { luminary in
                NavigationLink {
                    LuminaryDetailView(luminary: luminary)
                } label: {
                    LuminaryRow(luminary: luminary)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.subheadline.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Education Card

private struct EducationCard: View {
    let option: EducationOption

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: option.type.icon)
                    .foregroundStyle(option.type.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.name)
                        .font(.subheadline.bold())
                    Text(option.type.displayName)
                        .font(.caption)
                        .foregroundStyle(option.type.color)
                }
                Spacer()
            }

            HStack(spacing: 16) {
                Label(option.duration, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(option.formattedCost, systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(option.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Luminary Row

struct LuminaryRow: View {
    let luminary: Luminary

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: luminary.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(luminary.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(luminary.field)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
