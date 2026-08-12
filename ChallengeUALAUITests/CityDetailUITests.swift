//
//  CityDetailUITests.swift
//  ChallengeUALAUITests
//
//  Created by Juan Francisco Bazan Carrizo on 12/08/2026.
//

import XCTest

final class CityDetailUITests: XCTestCase {

    override func tearDown() {
        MainActor.assumeIsolated { XCUIDevice.shared.orientation = .portrait }
        super.tearDown()
    }

    @MainActor
    func test_tappingTheInfoButton_opensTheDetailOfThatCity() {
        let app = launchAppWithTheDetailOfTheFirstCityOpen()

        XCTAssertTrue(
            app.navigationBars[firstCityTitle].buttons["Cerrar"].exists,
            "no se abrió el detalle de la ciudad tocada"
        )
    }

    @MainActor
    func test_theCityDetail_showsTheCountryName() {
        let app = launchAppWithTheDetailOfTheFirstCityOpen()

        XCTAssertTrue(app.staticTexts["País, Argentina"].exists, "el detalle no muestra el nombre del país")
    }

    @MainActor
    func test_theCityDetail_showsTheCoordinatesInDegreesMinutesAndSeconds() {
        let app = launchAppWithTheDetailOfTheFirstCityOpen()

        XCTAssertTrue(app.staticTexts["Latitud, 1°00'00\" N"].exists, "el detalle no muestra la latitud en grados, minutos y segundos")
        XCTAssertTrue(app.staticTexts["Longitud, 1°00'00\" E"].exists, "el detalle no muestra la longitud en grados, minutos y segundos")
    }

    @MainActor
    func test_theCityDetail_showsTheCityIdentifier() {
        let app = launchAppWithTheDetailOfTheFirstCityOpen()

        XCTAssertTrue(app.staticTexts["Identificador, 1"].exists, "el detalle no muestra el identificador de la ciudad")
    }

    @MainActor
    func test_closingTheCityDetail_goesBackToTheList() {
        let app = launchAppWithTheDetailOfTheFirstCityOpen()

        app.navigationBars[firstCityTitle].buttons["Cerrar"].tap()

        XCTAssertTrue(firstCity(in: app).waitForExistence(timeout: 5), "no se volvió a la lista")
    }

    @MainActor
    func test_tappingTheInfoButtonInLandscape_opensTheSameDetail() {
        XCUIDevice.shared.orientation = .landscapeLeft

        let app = launchAppWithTheDetailOfTheFirstCityOpen()

        XCTAssertTrue(
            app.navigationBars[firstCityTitle].buttons["Cerrar"].exists,
            "el detalle no se abrió en landscape"
        )
    }

    @MainActor
    func test_selectingAnotherCityInLandscape_recentersTheMapOnIt() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchAppWithTestCatalog()

        firstCity(in: app).tap()
        XCTAssertTrue(mapMarker(named: firstCityTitle, in: app).waitForExistence(timeout: 10), "el mapa no se centró en la primera ciudad")

        app.staticTexts[secondCityTitle].tap()

        XCTAssertTrue(
            mapMarker(named: secondCityTitle, in: app).waitForExistence(timeout: 10),
            "el mapa no se recentró en la ciudad recién seleccionada"
        )
    }

    // MARK: - Helpers

    private var firstCityTitle: String { "\(UITestCityCatalog.firstCityName), AR" }

    private var secondCityTitle: String { "\(UITestCityCatalog.secondCityName), AR" }

    @MainActor
    private func launchAppWithTheDetailOfTheFirstCityOpen(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIApplication {
        let app = launchAppWithTestCatalog()
        _ = firstCity(in: app, file: file, line: line)

        app.buttons["Ver información de \(firstCityTitle)"].firstMatch.tap()

        XCTAssertTrue(
            app.navigationBars[firstCityTitle].waitForExistence(timeout: 10),
            "no apareció la pantalla de información",
            file: file,
            line: line
        )

        return app
    }

    @MainActor
    private func mapMarker(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.otherElements.matching(identifier: "AnnotationContainer").descendants(matching: .any)[name].firstMatch
    }
}
