import XCTest

// ---------------------------------------------------------------------------
// MARK: - Base helpers shared across all UI test suites
// ---------------------------------------------------------------------------

extension XCUIApplication {

    /// Launch the app with UI-test flags (student role by default).
    static func eduAssistLaunch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launch()
        return app
    }

    /// Launch the app bypassing Firebase auth as a teacher profile.
    static func eduAssistLaunchAsTeacher() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting", "--uitesting-role-teacher"]
        app.launchEnvironment["UITEST_DISABLE_ANIMATIONS"] = "1"
        app.launch()
        return app
    }

    // MARK: Sign-in helpers

    /// Signs in and waits for the tab bar to appear.
    ///
    /// When `--uitesting` is in the launch arguments, the app bypasses Firebase and
    /// renders MainTabView directly, so this helper just waits for the tab bar.
    /// Otherwise it fills the email/password form and submits.
    @discardableResult
    func signIn(email: String = "uitest.student@eduassist.test",
                password: String = "UITest123!") -> Bool {
        // --uitesting bypass: app renders MainTabView directly (no Firebase).
        // On iOS 26 iPad the TabView sidebar doesn't expose a XCUIElementType.tabBar,
        // so we look for tab buttons or navigation bars that appear on the first screen.
        if launchArguments.contains("--uitesting") {
            let tabBar   = tabBars.firstMatch
            let homeBtn  = buttons["Home"]
            let rosterBtn = buttons["Roster"]
            let navBar   = navigationBars.firstMatch
            let deadline = Date().addingTimeInterval(12)
            while Date() < deadline {
                if tabBar.exists || homeBtn.exists || rosterBtn.exists || navBar.exists { return true }
                Thread.sleep(forTimeInterval: 0.5)
            }
            return false
        }

        let emailField    = textFields["login_email_field"]
        let passwordField = secureTextFields["login_password_field"]
        let signInButton  = buttons["login_sign_in_button"]

        guard emailField.waitForExistence(timeout: 20) else { return false }
        emailField.tap()
        emailField.typeText(email)
        passwordField.tap()
        passwordField.typeText(password)
        signInButton.tap()

        return tabBars.firstMatch.waitForExistence(timeout: 30)
    }

    /// Signs out via the Profile tab's Sign Out button.
    /// Returns true when the login screen is visible again.
    @discardableResult
    func signOut() -> Bool {
        // Navigate to the Profile / Settings tab (last tab in all role layouts)
        let tabBar = tabBars.firstMatch
        tabBar.buttons.element(boundBy: tabBar.buttons.count - 1).tap()

        let signOutButton = buttons["sign_out_button"]
        guard signOutButton.waitForExistence(timeout: 5) else { return false }
        signOutButton.tap()

        // Sign-out succeeds when the login email field reappears within 5 s.
        // A freeze bug would cause this to time out and fail the test.
        return textFields["login_email_field"].waitForExistence(timeout: 5)
    }
}

// ---------------------------------------------------------------------------
// MARK: - Sign-Out Tests
// These are the primary regression tests for the sign-out freeze bugs.
// ---------------------------------------------------------------------------

final class SignOutUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // Signs out from the default landing tab (first tab).
    func testSignOutFromFirstTab() {
        let app = XCUIApplication.eduAssistLaunch()
        XCTAssertTrue(app.signIn(), "Login failed — check test account credentials")
        XCTAssertTrue(app.signOut(), "App froze or did not return to login screen")
    }

    // Cycles through every tab and signs out from each one. Each iteration
    // relaunches the app to start clean. A 5-second timeout on the login
    // screen check is the freeze detector — any hang longer than that fails.
    func testSignOutFromEveryTab() {
        for tabIndex in 0..<5 {
            let app = XCUIApplication.eduAssistLaunch()
            guard app.signIn() else {
                XCTFail("Login failed at tab index \(tabIndex)")
                return
            }

            // Navigate to the target tab before signing out
            let tabBar = app.tabBars.firstMatch
            if tabIndex < tabBar.buttons.count {
                tabBar.buttons.element(boundBy: tabIndex).tap()
                // Allow the tab to fully load
                _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
            }

            XCTAssertTrue(
                app.signOut(),
                "App froze or did not return to login screen after sign-out from tab \(tabIndex)"
            )
            app.terminate()
        }
    }

    // Regression test for "prevent freeze/crash on Sign Out when a Learning sheet is open".
    // Opens the Learning tab, taps the first item to present a sheet, then signs out.
    func testSignOutWithLearningSheetOpen() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Login failed"); return }

        // Tap the Learning tab (index 1 for students)
        app.tabBars.firstMatch.buttons.element(boundBy: 1).tap()
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 3)

        // Try to open any sheet-presenting element (first cell, if any)
        if app.cells.firstMatch.waitForExistence(timeout: 3) {
            app.cells.firstMatch.tap()
            _ = app.sheets.firstMatch.waitForExistence(timeout: 2)
        }

        // Sign out with whatever sheet state we're in
        XCTAssertTrue(app.signOut(),
            "App froze when signing out with a Learning sheet potentially open")
    }

    // Regression test for the companion-active sign-out scenario:
    // opens the Companion tab, sends a message (triggering the Cloud Function call),
    // then signs out immediately without waiting for the reply.
    func testSignOutWithCompanionMessageInFlight() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Login failed"); return }

        // Navigate to Companion tab (index 2 for students)
        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()

        let inputField  = app.textFields["companion_input_field"]
        let sendButton  = app.buttons["companion_send_button"]

        if inputField.waitForExistence(timeout: 5) {
            inputField.tap()
            inputField.typeText("What is photosynthesis?")
            if sendButton.isEnabled { sendButton.tap() }
        }

        // Sign out immediately — Cloud Function call still in-flight.
        // The app must not freeze or crash during teardown of the companion view.
        XCTAssertTrue(app.signOut(),
            "App froze when signing out with a Companion message in-flight")
    }

    // Rapid sign-in / sign-out cycle — stresses the auth state machine
    // for back-to-back transitions that could expose a double-trigger.
    func testRapidSignInSignOut() {
        for cycle in 1...3 {
            let app = XCUIApplication.eduAssistLaunch()
            XCTAssertTrue(app.signIn(), "Login failed on cycle \(cycle)")
            XCTAssertTrue(app.signOut(), "Sign-out froze on cycle \(cycle)")
            app.terminate()
        }
    }
}

// ---------------------------------------------------------------------------
// MARK: - Companion Conversation Tests
// ---------------------------------------------------------------------------

final class CompanionUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // Verifies the Companion tab loads and the input field is available.
    func testCompanionViewLoads() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Login failed"); return }

        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()

        XCTAssertTrue(
            app.textFields["companion_input_field"].waitForExistence(timeout: 8),
            "Companion input field did not appear — view may have failed to load"
        )
    }

    // Sends a message and verifies the typing indicator or a reply appears,
    // confirming the Cloud Function round-trip is wired up.
    func testCompanionSendsMessageAndReceivesReply() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Login failed"); return }

        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()

        let inputField = app.textFields["companion_input_field"]
        let sendButton = app.buttons["companion_send_button"]

        guard inputField.waitForExistence(timeout: 8) else {
            XCTFail("Companion input field not found"); return
        }

        inputField.tap()
        inputField.typeText("What is the water cycle?")
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled after typing")
        sendButton.tap()

        // After send: the input field should clear
        let inputCleared = NSPredicate(format: "value == ''")
        expectation(for: inputCleared, evaluatedWith: inputField)
        waitForExpectations(timeout: 3)

        // A reply or typing indicator should appear within 30 s (generous for CI)
        let replyAppeared = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'water' OR label CONTAINS[c] 'cycle' OR label CONTAINS[c] 'evaporation'")
        ).firstMatch
        XCTAssertTrue(
            replyAppeared.waitForExistence(timeout: 30),
            "No reply containing expected water-cycle content appeared within 30 s"
        )
    }

    // Sends two messages and verifies the second reply uses context from the first,
    // testing the companion persistence fix (history must be loaded properly).
    func testCompanionMaintainsConversationContext() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Login failed"); return }

        app.tabBars.firstMatch.buttons.element(boundBy: 2).tap()

        let inputField = app.textFields["companion_input_field"]
        let sendButton = app.buttons["companion_send_button"]
        guard inputField.waitForExistence(timeout: 8) else { XCTFail("No input field"); return }

        // First message
        inputField.tap()
        inputField.typeText("Tell me about photosynthesis")
        sendButton.tap()

        // Wait for a reply to appear before sending the follow-up
        let firstReply = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'photo' OR label CONTAINS[c] 'plant' OR label CONTAINS[c] 'light'")
        ).firstMatch
        guard firstReply.waitForExistence(timeout: 30) else {
            XCTFail("No reply to first message"); return
        }

        // Follow-up using a pronoun — this is the persistence regression test.
        // If history is broken, the AI asks "what subject?" instead of elaborating.
        inputField.tap()
        inputField.typeText("Can you explain that more simply?")
        sendButton.tap()

        // The reply must NOT be a generic clarifying question asking what subject
        let genericQuestion = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'what subject' OR label CONTAINS[c] 'what topic' OR label CONTAINS[c] 'what are you working on'")
        ).firstMatch

        // Give the reply 30 s to arrive
        _ = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'simple' OR label CONTAINS[c] 'plant' OR label CONTAINS[c] 'energy' OR label CONTAINS[c] 'sun'")
        ).firstMatch.waitForExistence(timeout: 30)

        XCTAssertFalse(
            genericQuestion.exists,
            "Companion lost context and asked a generic clarifying question instead of elaborating on photosynthesis"
        )
    }
}
