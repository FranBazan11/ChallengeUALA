//
//  CityCellViewModelTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import XCTest
import Cities

final class CityCellViewModelTests: XCTestCase {

    func test_init_combinesNameAndCountryCodeAsTitle() {
        let sut = makeSUT(name: "Hurzuf", countryCode: "UA")

        XCTAssertEqual(sut.title, "Hurzuf, UA")
    }

    func test_init_combinesLatitudeAndLongitudeAsSubtitle() {
        let sut = makeSUT(latitude: 44.549999, longitude: 34.283333)

        XCTAssertEqual(sut.subtitle, "44.549999, 34.283333")
    }

    func test_init_usesCityIDAsID() {
        let sut = makeSUT(id: 707860)

        XCTAssertEqual(sut.id, 707860)
    }

    func test_equatable_withSameCityData_areEqual() {
        let first = makeSUT(id: 1, name: "Alabama", countryCode: "US", latitude: 1, longitude: 2)
        let second = makeSUT(id: 1, name: "Alabama", countryCode: "US", latitude: 1, longitude: 2)

        XCTAssertEqual(first, second)
    }

    func test_init_takesIsFavoriteFromTheCaller() {
        XCTAssertTrue(makeSUT(isFavorite: true).isFavorite)
        XCTAssertFalse(makeSUT(isFavorite: false).isFavorite)
    }

    func test_equatable_withDifferentIsFavorite_areNotEqual() {
        let favorite = makeSUT(id: 1, isFavorite: true)
        let notFavorite = makeSUT(id: 1, isFavorite: false)

        XCTAssertNotEqual(favorite, notFavorite)
    }

    // MARK: - Helpers

    private func makeSUT(
        id: Int = 0,
        name: String = "any name",
        countryCode: String = "any country",
        latitude: Double = 0,
        longitude: Double = 0,
        isFavorite: Bool = false
    ) -> CityCellViewModel {
        let city = City(id: id, name: name, countryCode: countryCode, latitude: latitude, longitude: longitude)
        return CityCellViewModel(city: city, isFavorite: isFavorite)
    }
}
