import Foundation

@Observable
final class TestPrepViewModel {
    var attempts: [TestAttempt] = []
    var learningProfile: LearningProfile?
    var isLoading = false

    var studentGrade: Int? {
        guard let g = learningProfile?.grade, !g.isEmpty else { return nil }
        return Int(g)
    }

    var recommendedTests: [PracticeTest] {
        guard let grade = studentGrade else { return [] }
        return TestDataProvider.tests.filter { isRecommended($0, forGrade: grade) }
    }

    func isRecommended(_ test: PracticeTest, forGrade grade: Int) -> Bool {
        if test.type == .sat || test.type == .act { return grade >= 9 }
        guard let testGrade = Int(test.gradeLevel) else { return false }
        return abs(testGrade - grade) <= 1
    }

    func filtered(showForYouOnly: Bool, filterType: TestType?) -> [PracticeTest] {
        if showForYouOnly, let grade = studentGrade {
            return TestDataProvider.tests.filter { isRecommended($0, forGrade: grade) }
        } else if let t = filterType {
            return TestDataProvider.tests.filter { $0.type == t }
        }
        return TestDataProvider.tests
    }

    func bestScore(for testId: String) -> Int? {
        attempts.filter { $0.testId == testId }.map(\.score).max()
    }

    func load(studentId: String) async {
        isLoading = true
        async let fetchedAttempts = FirestoreService.shared.fetchTestAttempts(studentId: studentId)
        async let fetchedProfile  = FirestoreService.shared.fetchLearningProfile(studentId: studentId)
        attempts       = (try? await fetchedAttempts) ?? []
        learningProfile = try? await fetchedProfile
        isLoading = false
    }
}
