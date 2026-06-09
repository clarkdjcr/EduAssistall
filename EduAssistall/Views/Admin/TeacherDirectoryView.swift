import SwiftUI

struct TeacherDirectoryView: View {
    let adminProfile: UserProfile

    @State private var teachers: [UserProfile] = []
    @State private var isLoading = true
    @State private var searchText = ""

    private var districtId: String { adminProfile.districtId ?? "" }

    private var filtered: [UserProfile] {
        guard !searchText.isEmpty else { return teachers }
        let q = searchText.lowercased()
        return teachers.filter {
            $0.displayName.lowercased().contains(q) || $0.email.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if teachers.isEmpty {
                    ContentUnavailableView(
                        "No Teachers Found",
                        systemImage: "person.fill.questionmark",
                        description: Text("Teachers assigned to district \"\(districtId)\" will appear here.")
                    )
                } else {
                    List {
                        ForEach(filtered) { teacher in
                            NavigationLink {
                                TeacherAdminDetailView(teacher: teacher)
                            } label: {
                                TeacherSummaryRow(teacher: teacher)
                            }
                        }
                    }
                    #if os(iOS)
                    .listStyle(.insetGrouped)
                    #else
                    .listStyle(.inset)
                    #endif
                    .searchable(text: $searchText, prompt: "Search teachers")
                }
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Teachers")
            .inlineNavigationTitle()
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        guard !districtId.isEmpty else { isLoading = false; return }
        isLoading = true
        teachers = (try? await FirestoreService.shared.fetchTeachers(districtId: districtId)) ?? []
        isLoading = false
    }
}
