//
//  AdaptiveNavigationUITests.swift
//  Foundation Lab UITests
//

import XCTest

final class AdaptiveNavigationUITests: XCTestCase {
    private static let recipeTitle = "One-Shot Prompt"
    private static let layoutTimeout: TimeInterval = 10

    @MainActor
    func testRegularWidthLibraryShowsSidebarListAndEmptyDetail() throws {
        let app = try launchInRegularWidth()

        XCTAssertTrue(app.descendants(matching: .any)["sidebar.library"].exists)
        XCTAssertTrue(element(labeled: Self.recipeTitle, in: app).exists)
        XCTAssertTrue(app.staticTexts["No Experiment Selected"].exists)
    }

    @MainActor
    func testSelectingRecipeShowsPreview() throws {
        let app = try launchInRegularWidth()

        element(labeled: Self.recipeTitle, in: app).tap()

        XCTAssertTrue(app.buttons["Open in Playground"].waitForExistence(timeout: Self.layoutTimeout))
        XCTAssertFalse(app.staticTexts["No Experiment Selected"].exists)
    }

    @MainActor
    func testRegularWidthRunsShowsEmptyDetail() throws {
        let app = try launchInRegularWidth()

        app.descendants(matching: .any)["sidebar.runs"].tap()

        XCTAssertTrue(app.staticTexts["No Run Selected"].waitForExistence(timeout: Self.layoutTimeout))
    }
}

#if canImport(XCUIAutomation, _version: 25511)
extension AdaptiveNavigationUITests {
    private enum HingeAngle {
        static let unfolded: CGFloat = .pi
        static let folded: CGFloat = 0
    }

    @MainActor
    func testFoldingSwitchesToTabBarOnSelectedDestination() throws {
        let hinge = try requireHinge()
        let app = try launchInRegularWidth()
        app.descendants(matching: .any)["sidebar.runs"].tap()

        hinge.angle = HingeAngle.folded

        let runsTab = app.tabBars.buttons["Runs"]
        XCTAssertTrue(runsTab.waitForExistence(timeout: Self.layoutTimeout))
        XCTAssertTrue(runsTab.isSelected)
        XCTAssertTrue(app.descendants(matching: .any)["sidebar.runs"].waitForNonExistence(timeout: Self.layoutTimeout))
    }

    @MainActor
    func testFoldRoundTripKeepsRecipeSelection() throws {
        let hinge = try requireHinge()
        let app = try launchInRegularWidth()
        element(labeled: Self.recipeTitle, in: app).tap()
        XCTAssertTrue(app.buttons["Open in Playground"].waitForExistence(timeout: Self.layoutTimeout))

        hinge.angle = HingeAngle.folded
        let libraryTab = app.tabBars.buttons["Library"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: Self.layoutTimeout))
        XCTAssertTrue(libraryTab.isSelected)

        hinge.angle = HingeAngle.unfolded
        XCTAssertTrue(app.tabBars.firstMatch.waitForNonExistence(timeout: Self.layoutTimeout))
        XCTAssertTrue(app.buttons["Open in Playground"].waitForExistence(timeout: Self.layoutTimeout))
        XCTAssertFalse(app.staticTexts["No Experiment Selected"].exists)
    }

    @MainActor
    private func requireHinge() throws -> XCUIHinge {
        guard let hinge = XCUIDevice.shared.hinge else {
            throw XCTSkip("Requires a device with a hinge, such as an iPhone Duo simulator.")
        }
        return hinge
    }

    @MainActor
    private func unfoldHingeIfPresent() -> Bool {
        guard let hinge = XCUIDevice.shared.hinge else { return false }
        hinge.angle = HingeAngle.unfolded
        return true
    }
}
#endif

private extension AdaptiveNavigationUITests {
    @MainActor
    func launchInRegularWidth() throws -> XCUIApplication {
#if canImport(XCUIAutomation, _version: 25511)
        let hasHinge = unfoldHingeIfPresent()
#else
        let hasHinge = false
#endif

        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let showsSidebar = app.descendants(matching: .any)["sidebar.library"].waitForExistence(timeout: Self.layoutTimeout)
        if !hasHinge, !showsSidebar {
            throw XCTSkip("Requires a regular-width layout, such as an unfolded iPhone Duo or an iPad.")
        }
        XCTAssertTrue(showsSidebar, "An unfolded iPhone Duo should show the split view sidebar.")
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        return app
    }

    @MainActor
    func element(labeled label: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }
}
