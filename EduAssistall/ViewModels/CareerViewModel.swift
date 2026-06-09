import Foundation

@Observable
final class CareerViewModel {
    var learningProfile: LearningProfile?

    var interests: [String] { learningProfile?.interests ?? [] }

    var forYouCareers: [CareerPath] {
        CareerDataProvider.careers(matchingInterests: interests)
    }

    var forYouLuminaries: [Luminary] {
        CareerDataProvider.luminaries(matchingInterests: interests)
    }

    func loadProfile(studentId: String) async {
        learningProfile = try? await FirestoreService.shared.fetchLearningProfile(studentId: studentId)
    }
}
