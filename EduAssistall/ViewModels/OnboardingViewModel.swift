import Foundation

@Observable
final class OnboardingViewModel {
    var step: OnboardingStep
    var learningProfile: LearningProfile
    var teacherSchool = ""
    var teacherGrades: [String] = []
    var linkedStudentEmail = ""

    init(profile: UserProfile) {
        step = Self.initialStep(for: profile)
        learningProfile = LearningProfile(studentId: profile.id)
    }

    static func initialStep(for profile: UserProfile) -> OnboardingStep {
        switch profile.role {
        case .student: return .learningStyleAssessment
        case .teacher: return .teacherSetup
        case .parent:  return .parentSetup
        case .admin:   return .complete
        }
    }

    func finishOnboarding(profile: UserProfile, authVM: AuthViewModel) async {
        do {
            if profile.role == .student {
                learningProfile.assessmentCompleted = true
                learningProfile.updatedAt = Date()
                try await FirestoreService.shared.saveLearningProfile(learningProfile)
            }
            try await authVM.completeOnboarding()
        } catch {
            // Phase 2: surface this error properly
        }
    }
}
