//
//  UpdateMealPlanFlowUITests.swift
//  MealPrepUITests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import XCTest

/// Covers the route a returning user takes: land on the week, then step back
/// into the configuration screens to build a new plan. Uses the seeded
/// preview plan so no real generation is spent.
final class UpdateMealPlanFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchWithStoredPlan() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-seedPreviewPlan"]
        app.launch()
        return app
    }

    func testAStoredPlanOpensStraightToTheWeekNotOnboarding() {
        let app = launchWithStoredPlan()

        XCTAssertTrue(
            app.staticTexts["Buon appetit!"].waitForExistence(timeout: 5),
            "A returning user should land on the weekly plan"
        )
        XCTAssertFalse(
            app.buttons["Create your meal plan"].exists,
            "The lander belongs to first-run only"
        )
    }

    func testUpdatingAPlanReturnsToTheConfigurationScreens() {
        let app = launchWithStoredPlan()

        let updateButton = app.buttons["Update meal plan"]
        XCTAssertTrue(updateButton.waitForExistence(timeout: 5))
        updateButton.tap()

        XCTAssertTrue(
            app.staticTexts["What's your budget?"].waitForExistence(timeout: 5),
            "Updating should open the budget step"
        )
    }

    func testTheUserCanBackOutOfUpdatingAndKeepTheirPlan() {
        let app = launchWithStoredPlan()

        app.buttons["Update meal plan"].tap()
        XCTAssertTrue(app.staticTexts["What's your budget?"].waitForExistence(timeout: 5))

        // The back control is the only button in the progress row.
        app.buttons.firstMatch.tap()

        // Discarding must land back on the existing plan, not lose it.
        let keepEditing = app.buttons["Keep editing"]
        if keepEditing.waitForExistence(timeout: 2) {
            app.buttons["Discard changes"].tap()
        }

        XCTAssertTrue(
            app.staticTexts["Buon appetit!"].waitForExistence(timeout: 5),
            "Backing out should return to the existing plan"
        )
    }
}
