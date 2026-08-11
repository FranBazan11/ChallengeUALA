//
//  CityListKeyboardUITests.swift
//  ChallengeUALAUITests
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

import XCTest

@MainActor
final class CityListKeyboardUITests: XCTestCase {

    func test_tappingOnTheLoadedList_dismissesTheKeyboard() {
        let app = launchWithKeyboardShownOverTheLoadedList()

        app.buttons["Agregar a favoritos"].firstMatch.tap()

        XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 5), "el teclado no se escondió")
    }

    func test_scrollingTheLoadedList_dismissesTheKeyboard() {
        let app = launchWithKeyboardShownOverTheLoadedList()

        app.swipeUp()

        XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 5), "el teclado no se escondió al scrollear")
    }

    func test_dismissingTheKeyboard_keepsTheTypedFilter() {
        let app = launchWithKeyboardShownOverTheLoadedList()

        app.swipeUp()
        XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 5))

        XCTAssertEqual(filterField(in: app).value as? String, UITestCityCatalog.sharedPrefix, "se perdió el texto del filtro")
    }

    func test_dismissingTheKeyboard_keepsTheFilteredResults() {
        let app = launchWithKeyboardShownOverTheLoadedList()

        app.swipeUp()
        XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 5))

        XCTAssertFalse(app.staticTexts["\(UITestCityCatalog.cityOutsideTheSharedPrefixName), UA"].exists, "el filtro dejó de aplicarse al esconder el teclado")
    }

    // MARK: - Helpers

    private func launchWithKeyboardShownOverTheLoadedList(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIApplication {
        let app = launchAppWithTestCatalog()

        let filter = filterField(in: app, file: file, line: line)
        filter.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 10), "el teclado no apareció", file: file, line: line)
        filter.typeText(UITestCityCatalog.sharedPrefix)

        _ = firstCity(in: app, file: file, line: line)

        return app
    }
}
