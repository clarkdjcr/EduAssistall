import SwiftUI

struct RoleConfirmationView: View {
    let profile: UserProfile
    let onContinue: () -> Void

    private var roleIcon: String {
        switch profile.role {
        case .student: return "book.fill"
        case .teacher: return "person.fill.checkmark"
        case .parent: return "figure.2.and.child.holdinghands"
        case .admin: return "shield.fill"
        }
    }

    private var roleTitle: String {
        switch profile.role {
        case .student: return "Welcome, Learner!"
        case .teacher: return "Welcome, Educator!"
        case .parent: return "Welcome, Guardian!"
        case .admin: return "Welcome, Admin!"
        }
    }

    private var roleDescription: String {
        switch profile.role {
        case .student:
            return "We'll personalize your learning experience based on your style, interests, and goals."
        case .teacher:
            return "You'll have full visibility into student progress and control over AI-generated recommendations."
        case .parent:
            return "You can monitor your child's progress, approve learning content, and stay in the loop every step of the way."
        case .admin:
            return "You have district-wide visibility and control over safety policies and user management."
        }
    }

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            Image(systemName: roleIcon)
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .symbolEffect(.bounce, value: true)

            VStack(spacing: 12) {
                Text(roleTitle)
                    .font(.title.bold())

                Text("Hi, \(profile.displayName)!")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(roleDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Let's Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .navigationTitle("Welcome")
        .inlineNavigationTitle()
    }
}
