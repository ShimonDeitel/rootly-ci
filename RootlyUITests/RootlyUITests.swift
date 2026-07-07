import XCTest

final class RootlyUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsSeedCuttingAndPatienceCard() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["Pothos"].waitForExistence(timeout: 12))
        let patience = app.descendants(matching: .any).matching(identifier: "patienceCard").firstMatch
        XCTAssertTrue(patience.waitForExistence(timeout: 12), "Patience card did not appear")
    }

    func testAdvanceStageProgressesLabel() throws {
        let app = launchApp()
        let advanceButton = app.buttons["advanceStageButton_Pothos"]
        XCTAssertTrue(advanceButton.waitForExistence(timeout: 12))
        advanceButton.tap()

        XCTAssertTrue(app.staticTexts["Roots Growing"].waitForExistence(timeout: 12), "Stage did not advance")
    }

    func testAddCuttingFromHome() throws {
        let app = launchApp()
        let addButton = app.buttons["addCuttingButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["plantNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Snake Plant")

        app.buttons["saveCuttingButton"].tap()

        XCTAssertTrue(app.staticTexts["Snake Plant"].waitForExistence(timeout: 12), "New cutting did not appear")
    }

    func testDeleteCuttingViaForm() throws {
        let app = launchApp()
        let pothosText = app.staticTexts["Pothos"]
        XCTAssertTrue(pothosText.waitForExistence(timeout: 12))
        pothosText.tap()

        app.buttons["deleteCuttingButton"].tap()

        XCTAssertFalse(app.staticTexts["Pothos"].waitForExistence(timeout: 6), "Cutting was not deleted")
    }

    func testFreeLimitTriggersPaywallAtFourthCutting() throws {
        let app = launchApp()
        // Seed has 1 cutting, free limit is 3 — add 2 more to hit the limit.
        for name in ["Fern", "Ivy"] {
            let addButton = app.buttons["addCuttingButton"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 12))
            addButton.tap()
            let nameField = app.textFields["plantNameField"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 12))
            nameField.tap()
            nameField.typeText(name)
            app.buttons["saveCuttingButton"].tap()
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 12))
        }

        let addButton = app.buttons["addCuttingButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Rootly Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free cutting limit")
    }

    func testSettingsKeyboardDismissOnTap() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let toggle = app.switches["waterRemindersToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 12))
        toggle.tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    func testCuttingFormDismissesKeyboardOnOutsideTap() throws {
        let app = launchApp()
        let addButton = app.buttons["addCuttingButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()

        let nameField = app.textFields["plantNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 12))
        nameField.tap()
        nameField.typeText("Basil")

        app.staticTexts["Cutting"].tap()
        XCTAssertFalse(app.keyboards.element.exists, "Keyboard did not dismiss on tap-outside")
    }
}
