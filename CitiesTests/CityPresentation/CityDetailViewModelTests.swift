//
//  CityDetailViewModelTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 12/08/2026.
//

import XCTest
import Cities

final class CityDetailViewModelTests: XCTestCase {

    func test_init_buildsTheTitleFromTheNameAndTheCountryCode() {
        let sut = makeSUT(name: "Hurzuf", countryCode: "UA")

        XCTAssertEqual(sut.title, "Hurzuf, UA")
    }

    func test_init_translatesTheCountryCodeIntoItsFullName() {
        let sut = makeSUT(countryCode: "UA")

        XCTAssertEqual(sut.countryName, "Ucrania")
    }

    func test_init_withAnUnknownCountryCode_keepsTheCodeAsIs() {
        let sut = makeSUT(countryCode: "XX")

        XCTAssertEqual(sut.countryName, "XX")
    }

    func test_init_expressesTheLatitudeInDegreesMinutesAndSeconds() {
        let sut = makeSUT(latitude: 40.5)

        XCTAssertEqual(sut.latitudeText, "40°30'00\" N")
    }

    func test_init_expressesTheLongitudeInDegreesMinutesAndSeconds() {
        let sut = makeSUT(longitude: 3.25)

        XCTAssertEqual(sut.longitudeText, "3°15'00\" E")
    }

    func test_init_withANegativeLatitude_marksTheSouthernHemisphere() {
        let sut = makeSUT(latitude: -33.867851)

        XCTAssertEqual(sut.latitudeText, "33°52'04\" S")
    }

    func test_init_withANegativeLongitude_marksTheWesternHemisphere() {
        let sut = makeSUT(longitude: -106.650421)

        XCTAssertEqual(sut.longitudeText, "106°39'02\" O")
    }

    func test_init_atTheEquator_marksTheNorthernHemisphere() {
        let sut = makeSUT(latitude: 0)

        XCTAssertEqual(sut.latitudeText, "0°00'00\" N")
    }

    func test_init_atThePrimeMeridian_marksTheEasternHemisphere() {
        let sut = makeSUT(longitude: 0)

        XCTAssertEqual(sut.longitudeText, "0°00'00\" E")
    }

    func test_init_whenTheSecondsRoundToSixty_carriesIntoTheMinutes() {
        let sut = makeSUT(latitude: 44.549999)

        XCTAssertEqual(sut.latitudeText, "44°33'00\" N")
    }

    func test_init_whenTheMinutesRoundToSixty_carriesIntoTheDegrees() {
        let sut = makeSUT(latitude: 44.99999)

        XCTAssertEqual(sut.latitudeText, "45°00'00\" N")
    }

    func test_init_deliversTheIdentifierAsTextWithoutAGroupingSeparator() {
        let sut = makeSUT(id: 707_860)

        XCTAssertEqual(sut.identifierText, "707860")
    }

    func test_init_publishesTheFavoriteStateItWasGiven() {
        let sut = makeSUT(isFavorite: true)

        XCTAssertTrue(sut.isFavorite)
    }

    func test_init_carriesTheMapViewModelOfTheSameCity() {
        let city = makeCity(
            id: 707_860,
            name: "Hurzuf",
            countryCode: "UA",
            latitude: 44.549999,
            longitude: 34.283333
        ).model

        let sut = makeSUT()

        XCTAssertEqual(sut.map, CityMapViewModel(city: city))
    }

    // MARK: - Helpers

    private func makeSUT(
        id: Int = 707_860,
        name: String = "Hurzuf",
        countryCode: String = "UA",
        latitude: Double = 44.549999,
        longitude: Double = 34.283333,
        isFavorite: Bool = false,
        locale: Locale = Locale(identifier: "es_AR")
    ) -> CityDetailViewModel {
        CityDetailViewModel(
            city: makeCity(
                id: id,
                name: name,
                countryCode: countryCode,
                latitude: latitude,
                longitude: longitude
            ).model,
            isFavorite: isFavorite,
            locale: locale
        )
    }
}
