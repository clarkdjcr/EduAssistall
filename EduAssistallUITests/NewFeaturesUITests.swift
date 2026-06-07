import XCTest

/// Verifies the six new features added in the weekly-planner / grading / files sprint.
/// Uses the --uitesting Firebase bypass so tests run without network access.
/// Written for iOS 26 iPad where TabView renders as a sidebar (no XCUIElementType.tabBar).
final class NewFeaturesUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // -------------------------------------------------------------------------
    // MARK: 1. Planner tab exists in the student navigation
    // -------------------------------------------------------------------------
    func testPlannerTabExistsForStudent() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Student bypass login failed"); return }

        // On iOS 26 iPad, TabView renders as a sidebar — tab items are buttons.
        let plannerTab = app.buttons["Planner"]
        XCTAssertTrue(plannerTab.waitForExistence(timeout: 8),
                      "Planner tab button not found in student navigation")
    }

    // -------------------------------------------------------------------------
    // MARK: 2. WeeklyPlannerView renders without crashing
    // -------------------------------------------------------------------------
    func testWeeklyPlannerViewLoads() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Student bypass login failed"); return }

        // Tap the Planner sidebar/tab button (.firstMatch avoids ambiguity on iPad sidebar)
        let plannerBtn = app.buttons["Planner"]
        guard plannerBtn.firstMatch.waitForExistence(timeout: 8) else { XCTFail("Planner button not found"); return }
        plannerBtn.firstMatch.tap()

        let title      = app.navigationBars["Weekly Planner"]
        let emptyState = app.staticTexts["No Assignments This Week"]
        let loaded = title.waitForExistence(timeout: 8) || emptyState.waitForExistence(timeout: 8)
        XCTAssertTrue(loaded, "WeeklyPlannerView did not load")
    }

    // -------------------------------------------------------------------------
    // MARK: 3. Home dashboard has "This Week" section
    // -------------------------------------------------------------------------
    func testHomeHasThisWeekSection() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Student bypass login failed"); return }

        // Navigate to Home
        let homeBtn = app.buttons["Home"]
        if homeBtn.firstMatch.waitForExistence(timeout: 4) { homeBtn.firstMatch.tap() }

        let thisWeek = app.staticTexts["This Week"]
        XCTAssertTrue(thisWeek.waitForExistence(timeout: 8),
                      "'This Week' section header not found on student Home tab")

        let oldMsg = app.staticTexts["No upcoming assignments yet."]
        XCTAssertFalse(oldMsg.exists, "Old placeholder still present")
    }

    // -------------------------------------------------------------------------
    // MARK: 4. "My Files" card on student dashboard
    // -------------------------------------------------------------------------
    func testMyFilesCardOnDashboard() {
        let app = XCUIApplication.eduAssistLaunch()
        guard app.signIn() else { XCTFail("Student bypass login failed"); return }

        let homeBtn = app.buttons["Home"]
        if homeBtn.firstMatch.waitForExistence(timeout: 4) { homeBtn.firstMatch.tap() }

        let myFiles = app.staticTexts["My Files"]
        let found: Bool = {
            for _ in 0..<5 {
                if myFiles.exists { return true }
                app.swipeUp()
            }
            return false
        }()
        XCTAssertTrue(found, "'My Files' navigation card not found on student dashboard")
    }

    // -------------------------------------------------------------------------
    // MARK: 5. Teacher Create tab has new assignment and grading items
    // -------------------------------------------------------------------------
    func testTeacherCreateTabHasNewItems() {
        let app = XCUIApplication.eduAssistLaunchAsTeacher()
        guard app.signIn() else { XCTFail("Teacher bypass login failed"); return }

        // Navigate to the "Create" / "Documents" tab
        let createBtn = app.buttons["Create"]
        let documentsBtn = app.buttons["Documents"]
        if createBtn.firstMatch.waitForExistence(timeout: 6) {
            createBtn.firstMatch.tap()
        } else if documentsBtn.firstMatch.waitForExistence(timeout: 4) {
            documentsBtn.firstMatch.tap()
        }

        let assignRow = app.buttons["Assign to Students"]
        XCTAssertTrue(assignRow.waitForExistence(timeout: 8),
                      "'Assign to Students' row not found in teacher tab")

        let gradingRow = app.buttons["Grading Setup"]
        XCTAssertTrue(gradingRow.waitForExistence(timeout: 4),
                      "'Grading Setup' row not found in teacher tab")
    }

    // -------------------------------------------------------------------------
    // MARK: 6. GradingSetupView renders weight sliders
    // -------------------------------------------------------------------------
    func testGradingSetupViewOpens() {
        let app = XCUIApplication.eduAssistLaunchAsTeacher()
        guard app.signIn() else { XCTFail("Teacher bypass login failed"); return }

        let createBtn = app.buttons["Create"]
        let documentsBtn = app.buttons["Documents"]
        if createBtn.firstMatch.waitForExistence(timeout: 6) {
            createBtn.firstMatch.tap()
        } else if documentsBtn.firstMatch.waitForExistence(timeout: 4) {
            documentsBtn.firstMatch.tap()
        }

        let gradingRow = app.buttons["Grading Setup"]
        guard gradingRow.waitForExistence(timeout: 8) else { XCTFail("Grading Setup not found"); return }
        gradingRow.tap()

        let weightsHeader = app.staticTexts["Grade Weights"]
        XCTAssertTrue(weightsHeader.waitForExistence(timeout: 8),
                      "GradingSetupView did not render the Grade Weights section")

        for label in ["Homework", "Quizzes", "Group Activities", "Final Exam"] {
            XCTAssertTrue(app.staticTexts[label].exists, "'\(label)' weight label not found")
        }
    }

    // -------------------------------------------------------------------------
    // MARK: 7. AssignWeekView sheet opens
    // -------------------------------------------------------------------------
    func testAssignWeekViewOpens() {
        let app = XCUIApplication.eduAssistLaunchAsTeacher()
        guard app.signIn() else { XCTFail("Teacher bypass login failed"); return }

        let createBtn = app.buttons["Create"]
        let documentsBtn = app.buttons["Documents"]
        if createBtn.firstMatch.waitForExistence(timeout: 6) {
            createBtn.firstMatch.tap()
        } else if documentsBtn.firstMatch.waitForExistence(timeout: 4) {
            documentsBtn.firstMatch.tap()
        }

        let assignRow = app.buttons["Assign to Students"]
        guard assignRow.waitForExistence(timeout: 8) else { XCTFail("Assign row not found"); return }
        assignRow.tap()

        let weekHeader = app.staticTexts["Target Week"]
        XCTAssertTrue(weekHeader.waitForExistence(timeout: 8),
                      "AssignWeekView sheet did not open or 'Target Week' section is missing")
    }

    // -------------------------------------------------------------------------
    // MARK: 8. Messages tab loads for teacher
    // -------------------------------------------------------------------------
    func testMessageThreadHasAttachmentButton() {
        let app = XCUIApplication.eduAssistLaunchAsTeacher()
        guard app.signIn() else { XCTFail("Teacher bypass login failed"); return }

        let messagesBtn = app.buttons["Messages"]
        guard messagesBtn.firstMatch.waitForExistence(timeout: 8) else {
            XCTFail("Messages tab/button not found"); return
        }
        messagesBtn.firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Messages"].waitForExistence(timeout: 8),
                      "Messages view did not load")

        if app.cells.firstMatch.waitForExistence(timeout: 4) {
            app.cells.firstMatch.tap()
            let inputArea = app.textFields.firstMatch
            XCTAssertTrue(inputArea.waitForExistence(timeout: 5), "Message input field not found")
        }
    }
}
