import SwiftUI

/// Root tab structure for users with role == .admin.
/// Replaces TeacherTabView for admin accounts — provides a school-wide view
/// rather than a single teacher's roster.
struct AdminTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            SchoolOverviewView(adminProfile: profile)
                .tabItem {
                    Label("Overview", systemImage: "building.2.fill")
                }

            TeacherDirectoryView(adminProfile: profile)
                .tabItem {
                    Label("Teachers", systemImage: "person.3.fill")
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
