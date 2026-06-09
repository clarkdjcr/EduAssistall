import SwiftUI

struct RoleConfirmationView: View {
    let profile: UserProfile

    init(profile: UserProfile, onContinue: @escaping (UserRole) -> Void) {
        self.profile = profile
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)
                    .padding(.top, 48)

                Text("Welcome, \(profile.displayName)!")
                    .font(.title.bold())

                Text("Your account role has already been assigned.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                RoleOptionCard(role: profile.role, isSelected: true) {}
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationTitle("Welcome")
        .inlineNavigationTitle()
    }
}

private struct RoleOptionCard: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch role {
        case .student: return "book.fill"
        case .teacher: return "person.fill.checkmark"
        case .parent:  return "figure.2.and.child.holdinghands"
        case .admin:   return "shield.fill"
        }
    }

    var title: String {
        switch role {
        case .student: return "Student"
        case .teacher: return "Teacher"
        case .parent:  return "Parent / Guardian"
        case .admin:   return "Admin"
        }
    }

    var description: String {
        switch role {
        case .student: return "I'm here to learn"
        case .teacher: return "I manage a classroom"
        case .parent:  return "I oversee my child's progress"
        case .admin:   return "District administrator"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.08) : Color.appSecondaryBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
