//
//  CityListKeyboardUITests.swift
//  ChallengeUALAUITests
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

import XCTest

final class CityListKeyboardUITests: XCTestCase {

    @MainActor
    func test_tappingOutsideTheFilter_dismissesTheKeyboard() {
        let app = launchWithKeyboardShown()

        tapOutsideTheFilter(in: app)

        XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 5), "el teclado no se escondió")
    }

    @MainActor
    func test_dismissingTheKeyboard_keepsTheTypedFilter() {
        let app = launchWithKeyboardShown()
        let filter = filterField(in: app)
        filter.typeText("Hurzuf")

        tapOutsideTheFilter(in: app)
        XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 5))

        XCTAssertEqual(filter.value as? String, "Hurzuf", "se perdió el texto del filtro al esconder el teclado")
    }

    // MARK: - Helpers

    @MainActor
    private func launchWithKeyboardShown(file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()

        filterField(in: app, file: file, line: line).tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 10), "el teclado no apareció", file: file, line: line)

        return app
    }

    @MainActor
    private func filterField(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let filter = app.textFields["Filtrar por prefijo"]
        XCTAssertTrue(filter.waitForExistence(timeout: 30), "no apareció el campo de filtro", file: file, line: line)
        return filter
    }

    @MainActor
    private func tapOutsideTheFilter(in app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
    }
}
