//
//  CityCatalogSearchTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import XCTest
import Cities

final class CityCatalogSearchTests: XCTestCase {

    func test_search_withPrefixMatchingSeveralCities_deliversOnlyMatchingCities() {
        expect(makeSUT(), searching: "Al", toDeliver: ["Alabama, US", "Albuquerque, US"])
    }

    func test_search_withLongerPrefix_narrowsDownToFewerCities() {
        expect(makeSUT(), searching: "Alb", toDeliver: ["Albuquerque, US"])
    }

    func test_search_isCaseInsensitive() {
        let sut = makeSUT()
        let expected = ["Alabama, US", "Albuquerque, US"]

        expect(sut, searching: "AL", toDeliver: expected)
        expect(sut, searching: "al", toDeliver: expected)
        expect(sut, searching: "aL", toDeliver: expected)
    }

    func test_search_withEmptyPrefix_deliversWholeCatalog() {
        expect(makeSUT(), searching: "", toDeliver: [
            "Alabama, US",
            "Albuquerque, US",
            "Anaheim, US",
            "Arizona, US",
            "Sydney, AU",
            "Sydney, US",
            "Ávila, ES"
        ])
    }

    func test_search_deliversCitiesSortedByCityAndThenCountry() {
        expect(makeSUT(), searching: "Sy", toDeliver: ["Sydney, AU", "Sydney, US"])
    }

    func test_search_withPrefixMatchingNoCity_deliversNoCities() {
        expect(makeSUT(), searching: "Zurich", toDeliver: [])
    }

    func test_search_withWhitespacePrefix_deliversNoCities() {
        expect(makeSUT(), searching: "   ", toDeliver: [])
    }

    func test_search_withSymbolsPrefix_deliversNoCities() {
        expect(makeSUT(), searching: "!@#$%^&*()", toDeliver: [])
    }

    func test_search_withExtremelyLongPrefix_deliversNoCities() {
        expect(makeSUT(), searching: String(repeating: "a", count: 10_000), toDeliver: [])
    }

    func test_search_withAccentedPrefix_matchesTheAccentedCity() {
        expect(makeSUT(), searching: "Á", toDeliver: ["Ávila, ES"])
    }

    func test_search_withUnaccentedPrefix_doesNotMatchTheAccentedCity() {
        expect(makeSUT(), searching: "A", toDeliver: [
            "Alabama, US",
            "Albuquerque, US",
            "Anaheim, US",
            "Arizona, US"
        ])
    }

    func test_search_withCityNameOutsideBasicMultilingualPlane_matchesItsPrefix() {
        let sut = makeSUT(with: [
            City(id: 1, name: "Alabama", countryCode: "US", latitude: 0, longitude: 0),
            City(id: 2, name: "Al\u{1F600}ville", countryCode: "XX", latitude: 0, longitude: 0)
        ])

        expect(sut, searching: "Al", toDeliver: ["Alabama, US", "Al\u{1F600}ville, XX"])
    }

    // MARK: - Helpers

    private func makeSUT() -> CityCatalog {
        makeSUT(with: [
            City(id: 4, name: "Arizona", countryCode: "US", latitude: 34.048927, longitude: -111.093735),
            City(id: 1, name: "Alabama", countryCode: "US", latitude: 32.318230, longitude: -86.902298),
            City(id: 5, name: "Sydney", countryCode: "AU", latitude: -33.868820, longitude: 151.209290),
            City(id: 7, name: "Ávila", countryCode: "ES", latitude: 40.656685, longitude: -4.681818),
            City(id: 2, name: "Albuquerque", countryCode: "US", latitude: 35.084385, longitude: -106.650421),
            City(id: 6, name: "Sydney", countryCode: "US", latitude: 45.734444, longitude: -84.691389),
            City(id: 3, name: "Anaheim", countryCode: "US", latitude: 33.836593, longitude: -117.914301)
        ])
    }

    private func makeSUT(with cities: [City]) -> CityCatalog {
        CityCatalog(cities: cities)
    }

    private func expect(
        _ sut: CityCatalog,
        searching prefix: String,
        toDeliver expectedTitles: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let titles = sut.search(prefix: prefix).map { "\($0.name), \($0.countryCode)" }

        XCTAssertEqual(titles, expectedTitles, "prefijo \"\(prefix)\"", file: file, line: line)
    }
}
