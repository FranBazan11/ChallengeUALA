//
//  CityMapViewModelTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest
import Cities

final class CityMapViewModelTests: XCTestCase {

    func test_init_combinesNameAndCountryCodeAsTitle() {
        let sut = makeSUT(name: "Hurzuf", countryCode: "UA")

        XCTAssertEqual(sut.title, "Hurzuf, UA")
    }

    func test_init_keepsTheCityCoordinatesUntransformed() {
        let sut = makeSUT(latitude: 44.549999, longitude: 34.283333)

        XCTAssertEqual(sut.latitude, 44.549999)
        XCTAssertEqual(sut.longitude, 34.283333)
    }

    func test_init_usesCityIDAsID() {
        let sut = makeSUT(id: 707860)

        XCTAssertEqual(sut.id, 707860)
    }

    func test_init_framesTheCityWithTheDefaultSpan() {
        let sut = makeSUT()

        XCTAssertEqual(sut.spanInMeters, CityMapViewModel.defaultSpanInMeters)
    }

    func test_equatable_withSameCityData_areEqual() {
        let first = makeSUT(id: 1, name: "Alabama", countryCode: "US", latitude: 1, longitude: 2)
        let second = makeSUT(id: 1, name: "Alabama", countryCode: "US", latitude: 1, longitude: 2)

        XCTAssertEqual(first, second)
    }

    func test_hashable_withSameCityData_collapseIntoASingleSetEntry() {
        let first = makeSUT(id: 1, name: "Alabama", countryCode: "US", latitude: 1, longitude: 2)
        let second = makeSUT(id: 1, name: "Alabama", countryCode: "US", latitude: 1, longitude: 2)

        XCTAssertEqual(Set([first, second]).count, 1)
    }

    // MARK: - Helpers

    private func makeSUT(
        id: Int = 0,
        name: String = "any name",
        countryCode: String = "any country",
        latitude: Double = 0,
        longitude: Double = 0
    ) -> CityMapViewModel {
        let city = City(id: id, name: name, countryCode: countryCode, latitude: latitude, longitude: longitude)
        return CityMapViewModel(city: city)
    }
}
