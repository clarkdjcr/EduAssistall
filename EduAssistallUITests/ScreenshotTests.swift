import XCTest

final class ScreenshotTests: XCTestCase {

    private var outputDir: String {
        let device = (ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "device")
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .components(separatedBy: .init(charactersIn: "()"))
            .joined()
            .components(separatedBy: "-")
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return "/tmp/eduassist-screenshots/\(device)"
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    @MainActor
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots"]
        app.launch()

        Thread.sleep(forTimeInterval: 1.5)
        capture(app, name: "01_companion")

        tapTab(app, label: "Dashboard")
        capture(app, name: "02_dashboard")

        tapTab(app, label: "Goals")
        capture(app, name: "03_goals")

        tapTab(app, label: "Monitor")
        capture(app, name: "04_teacher_monitor")

        tapTab(app, label: "Modes")
        capture(app, name: "05_mode_picker")
    }

    // MARK: - Helpers

    // Handles both iPhone tab bar and iPadOS 18 sidebar navigation.
    private func tapTab(_ app: XCUIApplication, label: String) {
        // iPadOS 18 sidebar: buttons live directly in app.buttons
        // iPhone tab bar: buttons live in app.tabBars
        let button = app.buttons[label].firstMatch
        if button.waitForExistence(timeout: 5) {
            button.tap()
        } else {
            // Fallback: tap anywhere in the tab bar matching the label
            let tabButton = app.tabBars.buttons[label].firstMatch
            XCTAssert(tabButton.waitForExistence(timeout: 5), "Tab '\(label)' not found")
            tabButton.tap()
        }
        Thread.sleep(forTimeInterval: 0.8)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let path = (outputDir as NSString).appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: path))

        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
