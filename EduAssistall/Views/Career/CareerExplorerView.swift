import SwiftUI

struct CareerExplorerView: View {
    let profile: UserProfile

    @State private var vm = CareerViewModel()
    @State private var selectedTab = 0
    @State private var showLuminaries = false

    private var displayedCareers: [CareerPath] {
        selectedTab == 0
            ? (vm.forYouCareers.isEmpty ? CareerDataProvider.careers : vm.forYouCareers)
            : CareerDataProvider.careers
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    Picker("View", selection: $selectedTab) {
                        Text("For You").tag(0)
                        Text("All Careers").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(displayedCareers) { career in
                            NavigationLink {
                                CareerDetailView(career: career, luminaries: CareerDataProvider.luminaries)
                            } label: {
                                CareerCard(career: career)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Meet the Luminaries")
                                .font(.headline)
                            Spacer()
                            Button("See All") { showLuminaries = true }
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                let displayed = vm.forYouLuminaries.isEmpty
                                    ? Array(CareerDataProvider.luminaries.prefix(5))
                                    : Array(vm.forYouLuminaries.prefix(5))
                                ForEach(displayed) { luminary in
                                    NavigationLink {
                                        LuminaryDetailView(luminary: luminary)
                                    } label: {
                                        LuminaryChip(luminary: luminary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Career Explorer")
            .inlineNavigationTitle()
            .sheet(isPresented: $showLuminaries) {
                LuminariesListView(interests: vm.interests)
            }
            .task { await vm.loadProfile(studentId: profile.id) }
        }
    }
}

// MARK: - Career Card

private struct CareerCard: View {
    let career: CareerPath

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(career.color.opacity(0.12))
                    .frame(height: 54)
                Image(systemName: career.icon)
                    .font(.title2)
                    .foregroundStyle(career.color)
            }

            Text(career.title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(career.averageSalary)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                Text(career.growthOutlook.components(separatedBy: " ").prefix(3).joined(separator: " "))
                    .font(.caption2)
            }
            .foregroundStyle(.green)
        }
        .padding(14)
        .background(Color.appSecondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Luminary Chip

private struct LuminaryChip: View {
    let luminary: Luminary

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: luminary.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            Text(luminary.name)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 72)
            Text(luminary.field)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 72)
        }
    }
}
