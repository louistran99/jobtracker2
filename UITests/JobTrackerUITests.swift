import XCTest

final class JobTrackerUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testBrowsingApplicationsAndSummary() {
        let app = launch(seedingSampleData: true)

        XCTAssertTrue(app.navigationBars["Applications"].waitForExistence(timeout: timeout))
        app.buttons["Stripe, EM, Mobile Platform"].tap()

        XCTAssertTrue(app.staticTexts["Stripe"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Onsite"].exists)

        app.navigationBars.buttons["Applications"].tap()
        XCTAssertTrue(app.buttons["Airbnb, EM, Guest Apps"].waitForExistence(timeout: timeout))

        app.tabBars.buttons["Summary"].tap()
        XCTAssertTrue(app.navigationBars["Summary"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["6, Total"].exists)
    }

    @MainActor
    func testAddingAnApplication() {
        let app = launch(seedingSampleData: false)

        XCTAssertTrue(app.staticTexts["No Applications"].waitForExistence(timeout: timeout))
        app.navigationBars["Applications"].buttons["Add Application"].tap()

        let add = app.navigationBars["New Application"].buttons["Add"]
        XCTAssertTrue(add.waitForExistence(timeout: timeout))
        XCTAssertFalse(add.isEnabled)

        // The company field has focus when the sheet opens.
        app.typeText("Ramp")
        app.textFields["Role"].tap()
        app.typeText("EM, Mobile")
        XCTAssertTrue(add.isEnabled)
        add.tap()

        let row = app.buttons["Ramp, EM, Mobile"]
        XCTAssertTrue(row.waitForExistence(timeout: timeout))
        row.tap()
        XCTAssertTrue(app.staticTexts["Applied"].waitForExistence(timeout: timeout))
    }

    @MainActor
    private func launch(seedingSampleData: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [LaunchArguments.uiTesting]
        if seedingSampleData {
            app.launchArguments.append(LaunchArguments.seedSampleData)
        }
        app.launch()
        return app
    }
}
