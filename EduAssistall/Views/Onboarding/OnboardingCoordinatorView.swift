import SwiftUI

enum OnboardingStep {
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
    @State private var vm: OnboardingViewModel

    init(profile: UserProfile) {
        self.profile = profile
        self._vm = State(initialValue: OnboardingViewModel(profile: profile))
    }

    var body: some View {
        @Bindable var vm = vm
        NavigationStack {
            Group {
                switch vm.step {
                case .learningStyleAssessment:
                    LearningStyleAssessmentView(profile: $vm.learningProfile) {
                        vm.step = .interests
                    }

                case .interests:
                    InterestsView(profile: $vm.learningProfile) {
                        vm.step = .gradeSelection
                    }

                case .gradeSelection:
                    GradeSelectionView(profile: $vm.learningProfile) {
                        vm.step = .aiDisclosure
                    }

                case .teacherSetup:
                    TeacherSetupView(school: $vm.teacherSchool, grades: $vm.teacherGrades, teacherId: profile.id) {
                        vm.step = .complete
                    }

                case .parentSetup:
                    ParentSetupView(studentEmail: $vm.linkedStudentEmail, adultId: profile.id) {
                        vm.step = .aiDisclosure
                    }

                case .aiDisclosure:
                    AIDisclosureView {
                        vm.step = .complete
                    }

                case .complete:
                    OnboardingCompleteView {
                        Task { await vm.finishOnboarding(profile: profile, authVM: authVM) }
                    }
                }
            }
            .hideBackButton()
        }
    }
}
