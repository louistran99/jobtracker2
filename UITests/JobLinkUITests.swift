import XCTest

/// The job link field's states (A6), on the debug-only job link screen.
///
/// The app stubs the network under UI tests (see `AppDependencies`): links to
/// linkedin.com can't be read, links whose path starts with `/slow` stay in
/// flight, and every other link can be read.
final class JobLinkUITests: XCTestCase {
    private let timeout: TimeInterval = 10
    private let unreadableFooter =
        "This posting couldn't be read. Fill in the company and role below. The link is still saved."

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAPostingThatCanBeReadIsFound() {
        let app = launch()
        enter("example.com/jobs/1", in: app)

        XCTAssertTrue(app.images["Posting found"].waitForExistence(timeout: timeout))
    }

    @MainActor
    func testAPostingIsFetchingWhileTheRequestIsInFlight() {
        let app = launch()
        enter("example.com/slow/1", in: app)

        XCTAssertTrue(app.activityIndicators["Checking link"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Fetching details. You can keep filling in the form."].exists)
    }

    @MainActor
    func testAPostingThatCantBeReadSaysSo() {
        let app = launch()
        enter("linkedin.com/jobs/view/4021198765", in: app)

        XCTAssertTrue(app.images["Couldn't read posting"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts[unreadableFooter].exists)
    }

    @MainActor
    func testASavedPostingIsAlreadyAdded() {
        // The sample Stripe application links to this posting, without the
        // tracking parameter.
        let app = launch()
        enter("stripe.com/jobs/listing/6519024?utm_source=linkedin", in: app)

        XCTAssertTrue(app.images["Already added"].waitForExistence(timeout: timeout))
        let addedOn = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'You added this on '"))
        XCTAssertEqual(addedOn.count, 1)
    }

    @MainActor
    func testTextThatIsntAWebAddressIsInvalid() {
        let app = launch()
        enter("stripe", in: app)

        XCTAssertTrue(app.images["Not a web address"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Enter a web address, like stripe.com/jobs/123."].exists)
    }

    @MainActor
    func testFixingALinkUpdatesItsState() {
        let app = launch()
        let unreadable = "linkedin.com/jobs/view/1"
        let field = enter(unreadable, in: app)
        XCTAssertTrue(app.images["Couldn't read posting"].waitForExistence(timeout: timeout))

        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: unreadable.count))
        field.typeText("example.com/jobs/1")

        XCTAssertTrue(app.images["Posting found"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.images["Couldn't read posting"].exists)
        XCTAssertFalse(app.staticTexts[unreadableFooter].exists)
    }

    /// Opens the job link screen with the sample applications saved.
    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments =
            [LaunchArguments.uiTesting, LaunchArguments.seedSampleData] + LaunchArguments.jobLinkScreen
        app.launch()
        return app
    }

    /// Types `text` into the link field.
    @MainActor
    @discardableResult
    private func enter(_ text: String, in app: XCUIApplication) -> XCUIElement {
        let field = app.textFields["Job link"]
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        field.typeText(text)
        return field
    }
}
