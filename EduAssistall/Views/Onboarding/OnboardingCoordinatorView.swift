import SwiftUI

enum OnboardingStep {
    case roleConfirmation
    case learningStyleAssessment  // student only
    case interests                // student only
    case gradeSelection           // student only
    case teacherSetup             // teacher only
    case parentSetup              // parent only
    case aiDisclosure             // student + parent: required AI usage disclosure
    case complete
}

struct OnboardingCoordinatorView: View {
    @Environment(AuthViewModel.self) private var authVM
    let profile: UserProfile

    @State private var step: OnboardingStep = .roleConfirmation
    @State private var learningProfile: LearningProfile
    @State private var teacherSchool = ""
    @State private var teacherGrades: [String] = []
    @State private var linkedStudentEmail = ""

    init(profile: UserProfile) {
        self.profile = profile
        self._learningProfile = State(initialValue: LearningProfile(studentId: profile.id))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .roleConfirmation:
                    RoleConfirmationView(profile: profile) {
                        advanceFromRoleConfirmation()
                    }

                case .learningStyleAssessment:
                    LearningStyleAssessmentView(profile: $learningProfile) {
                        step = .interests
                    }

                case .interests:
                    InterestsView(profile: $learningProfile) {
                        step = .gradeSelection
                    }

                case .gradeSelection:
                    GradeSelectionView(profile: $learningProfile) {
                        step = .aiDisclosure
                    }

                case .teacherSetup:
                    TeacherSetupView(school: $teacherSchool, grades: $teacherGrades, teacherId: profile.id) {
                        step = .complete
                    }

                case .parentSetup:
                    ParentSetupView(studentEmail: $linkedStudentEmail, adultId: profile.id) {
                        step = .aiDisclosure
                    }

                case .aiDisclosure:
                    AIDisclosureView {
                        step = .complete
                    }

                case .complete:
                    OnboardingCompleteView {
                        Task { await finishOnboarding() }
                    }
                }
            }
            .hideBackButton()
        }
    }

    private func advanceFromRoleConfirmation() {
        switch profile.role {
        case .student: step = .learningStyleAssessment
        case .teacher: step = .teacherSetup
        case .parent: step = .parentSetup
        case .admin: step = .complete
        }
    }

    private func finishOnboarding() async {
        do {
            if profile.role == .student {
                learningProfile.assessmentCompleted = true
                learningProfile.updatedAt = Date()
                try await FirestoreService.shared.saveLearningProfile(learningProfile)
            }
            try await authVM.completeOnboarding()
        } catch {
            // In Phase 2 we'll surface this error properly
        }
    }
}
