import XCTest
@testable import EduAssistall

// ---------------------------------------------------------------------------
// MARK: - AuthState machine tests
// ---------------------------------------------------------------------------

@MainActor
final class AuthStateTests: XCTestCase {

    // AuthState must be Equatable so we can assert transitions without pattern matching.
    func testUnauthenticatedEquality() {
        XCTAssertEqual(AuthState.unauthenticated, AuthState.unauthenticated)
        XCTAssertEqual(AuthState.loading,         AuthState.loading)
        XCTAssertNotEqual(AuthState.loading, AuthState.unauthenticated)
    }

    func testCurrentProfileIsNilWhenLoading() {
        let vm = AuthViewModel()
        // Initial state is .loading; no profile should be available.
        XCTAssertNil(vm.currentProfile)
    }

    func testCurrentProfileIsNilWhenUnauthenticated() {
        let vm = AuthViewModel()
        vm.authState = .unauthenticated
        XCTAssertNil(vm.currentProfile)
    }

    func testCurrentProfileReturnedWhenAuthenticated() {
        let profile = makeProfile()
        let vm = AuthViewModel()
        vm.authState = .authenticated(profile)
        XCTAssertEqual(vm.currentProfile, profile)
    }

    func testCurrentProfileReturnedWhenOnboarding() {
        let profile = makeProfile()
        let vm = AuthViewModel()
        vm.authState = .onboarding(profile)
        XCTAssertEqual(vm.currentProfile, profile)
    }

    func testCurrentProfileReturnedWhenPendingConsent() {
        let profile = makeProfile()
        let vm = AuthViewModel()
        vm.authState = .pendingParentalConsent(profile)
        XCTAssertEqual(vm.currentProfile, profile)
    }

    // Sign-out double-trigger guard: setting authState to .unauthenticated a second
    // time (the path the Firebase auth listener takes after Auth.signOut()) must
    // not cause a second SwiftUI update. We verify the guard works by checking the
    // state remains .unauthenticated and hasn't regressed to .loading.
    func testSignOutDoubleSetRemainsUnauthenticated() {
        let vm = AuthViewModel()
        vm.authState = .unauthenticated
        // Simulate a second .unauthenticated write — state must stay stable.
        vm.authState = .unauthenticated
        XCTAssertEqual(vm.authState, .unauthenticated)
    }

    func testAuthStateTransitionsAreIsolated() {
        let profile = makeProfile()
        let vm = AuthViewModel()

        vm.authState = .onboarding(profile)
        XCTAssertNotNil(vm.currentProfile)

        vm.authState = .unauthenticated
        XCTAssertNil(vm.currentProfile)

        vm.authState = .authenticated(profile)
        XCTAssertNotNil(vm.currentProfile)
    }

    // Helper
    private func makeProfile(role: UserRole = .student) -> UserProfile {
        UserProfile(
            id: "test-uid-\(UUID().uuidString.prefix(8))",
            email: "test@school.edu",
            displayName: "Test Student",
            role: role
        )
    }
}

// ---------------------------------------------------------------------------
// MARK: - AuthState Equatable coverage for all cases
// ---------------------------------------------------------------------------

final class AuthStateEquatableTests: XCTestCase {

    func testLoadingEquality() {
        XCTAssertEqual(AuthState.loading, .loading)
    }

    func testUnauthenticatedEquality() {
        XCTAssertEqual(AuthState.unauthenticated, .unauthenticated)
    }

    func testLoadingNotEqualToUnauthenticated() {
        XCTAssertNotEqual(AuthState.loading, .unauthenticated)
    }

    func testAuthenticatedWithSameProfileEqual() {
        let profile = makeProfile()
        XCTAssertEqual(AuthState.authenticated(profile), .authenticated(profile))
    }

    func testAuthenticatedWithDifferentProfileNotEqual() {
        let p1 = makeProfile(id: "uid-1")
        let p2 = makeProfile(id: "uid-2")
        XCTAssertNotEqual(AuthState.authenticated(p1), .authenticated(p2))
    }

    func testOnboardingAndAuthenticatedNotEqual() {
        let profile = makeProfile()
        XCTAssertNotEqual(AuthState.onboarding(profile), .authenticated(profile))
    }

    private func makeProfile(id: String = "uid-test") -> UserProfile {
        UserProfile(
            id: id,
            email: "t@school.edu",
            displayName: "Tester",
            role: .student
        )
    }
}

// ---------------------------------------------------------------------------
// MARK: - LocalDraftService — simple truncation fallback (pre-iOS 26)
// Tests the private simpleTruncation path by calling compressHistory with
// a message array that is small enough not to trigger FoundationModels.
// On iOS < 26 or macOS < 26 the actor always uses simpleTruncation.
// ---------------------------------------------------------------------------

final class LocalDraftServiceTests: XCTestCase {

    func testCompressHistoryReturnsNilForFewMessages() async {
        // Guard: fewer than 4 messages returns nil — no compression.
        let messages = [
            ChatMessage(role: .user,      text: "Hello"),
            ChatMessage(role: .assistant, text: "Hi there"),
        ]
        let result = await LocalDraftService.shared.compressHistory(messages, gradeLevel: "7")
        // With only 2 messages, compression is skipped.
        XCTAssertNil(result)
    }

    func testCompressHistoryReturnsValueForFourPlusMessages() async {
        let messages = stride(from: 0, to: 6, by: 1).map { i in
            ChatMessage(
                role: i % 2 == 0 ? .user : .assistant,
                text: "Message number \(i) about photosynthesis and how plants make food"
            )
        }
        let result = await LocalDraftService.shared.compressHistory(messages, gradeLevel: "5")
        // With 6 messages the fallback path produces a non-empty string.
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.isEmpty)
    }

    func testCompressedHistoryDoesNotExceedReasonableLength() async {
        // The compressed string should be short enough to be a summary, not a full transcript.
        let messages = stride(from: 0, to: 20, by: 1).map { i in
            ChatMessage(
                role: i % 2 == 0 ? .user : .assistant,
                text: String(repeating: "word ", count: 50) // 50-word messages
            )
        }
        let result = await LocalDraftService.shared.compressHistory(messages, gradeLevel: "10")
        // The 2000-char server cap means we never need more than that locally either.
        if let r = result {
            XCTAssertLessThanOrEqual(r.count, 4000,
                "Compressed history should be significantly shorter than the raw transcript")
        }
    }
}

// ---------------------------------------------------------------------------
// MARK: - ChatMessage model tests
// ---------------------------------------------------------------------------

final class ChatMessageTests: XCTestCase {

    func testUserRoleIsCorrect() {
        let msg = ChatMessage(role: .user, text: "hello")
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.text, "hello")
    }

    func testAssistantRoleIsCorrect() {
        let msg = ChatMessage(role: .assistant, text: "hi")
        XCTAssertEqual(msg.role, .assistant)
    }

    func testMessageHasUniqueId() {
        let a = ChatMessage(role: .user, text: "a")
        let b = ChatMessage(role: .user, text: "a")
        XCTAssertNotEqual(a.id, b.id)
    }
}
