//
//  CityCatalogUITests.swift
//  ChallengeUALAUITests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest

final class CityCatalogUITests: XCTestCase {

    override func tearDown() {
        MainActor.assumeIsolated { XCUIDevice.shared.orientation = .portrait }
        super.tearDown()
    }

    @MainActor
    func test_tappingACity_showsItOnTheMapScreen() {
        let app = launchAppWithTestCatalog()

        firstCity(in: app).tap()

        XCTAssertTrue(
            app.navigationBars["\(UITestCityCatalog.firstCityName), AR"].waitForExistence(timeout: 5),
            "no se navegó a la pantalla de mapa de la ciudad tocada"
        )
    }

    @MainActor
    func test_goingBackFromTheMap_keepsTheCityList() {
        let app = launchAppWithTestCatalog()
        firstCity(in: app).tap()
        XCTAssertTrue(app.navigationBars["\(UITestCityCatalog.firstCityName), AR"].waitForExistence(timeout: 5))

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(firstCity(in: app).waitForExistence(timeout: 5), "no se volvió a la lista")
    }

    @MainActor
    func test_scrollingToTheEndOfTheList_showsTheNextPage() {
        let app = launchAppWithTestCatalog()
        _ = firstCity(in: app)
        let cityBeyondTheFirstPage = app.staticTexts["\(UITestCityCatalog.cityBeyondTheFirstPageName), AR"]
        XCTAssertFalse(cityBeyondTheFirstPage.exists, "la primera página ya mostraba una ciudad más allá de la primera página")

        scrollToTheEnd(of: app)

        XCTAssertTrue(cityBeyondTheFirstPage.exists, "scrollear hasta el fondo no cargó la página siguiente")
    }

    @MainActor
    func test_rotatingToLandscape_keepsTheTypedFilter() {
        let app = launchAppWithTestCatalog()
        let filter = filterField(in: app)
        filter.tap()
        filter.typeText(UITestCityCatalog.sharedPrefix)
        _ = firstCity(in: app)

        XCUIDevice.shared.orientation = .landscapeLeft

        XCTAssertEqual(filterField(in: app).value as? String, UITestCityCatalog.sharedPrefix, "se perdió el texto del filtro al rotar")
    }

    @MainActor
    func test_rotatingToLandscape_keepsTheSelectedCity() {
        let app = launchAppWithTestCatalog()
        firstCity(in: app).tap()
        XCTAssertTrue(app.navigationBars["\(UITestCityCatalog.firstCityName), AR"].waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft

        XCTAssertTrue(
            app.staticTexts[emptyMapMessage].waitForNonExistence(timeout: 5),
            "el panel de mapa quedó sin ciudad seleccionada después de rotar"
        )
    }

    @MainActor
    func test_launchingInLandscape_showsTheEmptyMapPanelNextToTheList() {
        XCUIDevice.shared.orientation = .landscapeLeft

        let app = launchAppWithTestCatalog()

        _ = firstCity(in: app)
        XCTAssertTrue(app.staticTexts[emptyMapMessage].exists, "no se ve el panel de mapa junto a la lista")
    }

    @MainActor
    func test_selectingACityInLandscape_marksItsRowAsSelected() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchAppWithTestCatalog()

        firstCity(in: app).tap()

        XCTAssertTrue(
            row(for: UITestCityCatalog.firstCityName, in: app).isSelected,
            "la fila de la ciudad que está en el mapa no quedó marcada como seleccionada"
        )
    }

    @MainActor
    func test_selectingAnotherCityInLandscape_unmarksThePreviousRow() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = launchAppWithTestCatalog()
        firstCity(in: app).tap()

        app.staticTexts["\(UITestCityCatalog.secondCityName), AR"].tap()

        XCTAssertFalse(
            row(for: UITestCityCatalog.firstCityName, in: app).isSelected,
            "quedaron dos filas marcadas como seleccionadas a la vez"
        )
    }

    // MARK: - Helpers

    private var emptyMapMessage: String { "Elegí una ciudad para verla en el mapa" }

    @MainActor
    private func row(for cityName: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts["\(cityName), AR"]
    }

    @MainActor
    private func scrollToTheEnd(of app: XCUIApplication, swipes: Int = 12) {
        for _ in 0..<swipes {
            app.swipeUp(velocity: .fast)
        }
    }
}
