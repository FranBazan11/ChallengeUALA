//
//  TestCatalogApp.swift
//  ChallengeUALAUITests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest

private let cityCatalogJSONKey = "CITY_CATALOG_JSON"

@MainActor
func launchAppWithTestCatalog() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment[cityCatalogJSONKey] = UITestCityCatalog.json
    app.launch()
    return app
}

@MainActor
func filterField(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
    let filter = app.textFields["Filtrar por prefijo"]
    XCTAssertTrue(filter.waitForExistence(timeout: 30), "no apareció el campo de filtro", file: file, line: line)
    return filter
}

@MainActor
func firstCity(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
    let city = app.staticTexts["\(UITestCityCatalog.firstCityName), AR"]
    XCTAssertTrue(city.waitForExistence(timeout: 30), "no apareció la primera ciudad", file: file, line: line)
    return city
}
