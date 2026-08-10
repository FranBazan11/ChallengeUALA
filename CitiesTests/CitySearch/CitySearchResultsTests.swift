//
//  CitySearchResultsTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

import XCTest
import Cities

final class CitySearchResultsTests: XCTestCase {

    func test_filterByFavoriteIDs_withNoFavorites_deliversNoCities() {
        expect(makeSUT(), searching: "", keepingFavorites: [], toDeliver: [])
    }

    func test_filterByFavoriteIDs_deliversOnlyFavoriteCities() {
        expect(makeSUT(), searching: "", keepingFavorites: [1, 5], toDeliver: ["Alabama, US", "Sydney, AU"])
    }

    func test_filterByFavoriteIDs_preservesTheOrderOfTheSearchIndex() {
        expect(makeSUT(), searching: "", keepingFavorites: [5, 2, 3], toDeliver: [
            "Albuquerque, US",
            "Anaheim, US",
            "Sydney, AU"
        ])
    }

    func test_filterByFavoriteIDs_combinedWithAPrefix_deliversTheIntersection() {
        expect(makeSUT(), searching: "Al", keepingFavorites: [2, 5], toDeliver: ["Albuquerque, US"])
    }

    func test_filterByFavoriteIDs_withFavoritesOutsideThePrefixRange_deliversNoCities() {
        expect(makeSUT(), searching: "Sy", keepingFavorites: [1], toDeliver: [])
    }

    func test_filterByFavoriteIDs_withFavoriteIDsNotInTheCatalog_ignoresThem() {
        expect(makeSUT(), searching: "", keepingFavorites: [1, 999], toDeliver: ["Alabama, US"])
    }

    func test_limitedTo_deliversTheFirstResultsInIndexOrder() {
        let results = makeSUT().search(prefix: "").limited(to: 2)

        expect(results, toDeliver: ["Alabama, US", "Albuquerque, US"])
    }

    func test_limitedTo_aBoundLargerThanTheResults_deliversAllOfThem() {
        let results = makeSUT().search(prefix: "Al").limited(to: 99)

        expect(results, toDeliver: ["Alabama, US", "Albuquerque, US"])
    }

    func test_limitedTo_zero_deliversNoCities() {
        let results = makeSUT().search(prefix: "").limited(to: 0)

        expect(results, toDeliver: [])
    }

    func test_limitedTo_afterFilteringFavorites_deliversTheFirstFavorites() {
        let results = makeSUT().search(prefix: "").filter(byFavoriteIDs: [1, 3, 5]).limited(to: 2)

        expect(results, toDeliver: ["Alabama, US", "Anaheim, US"])
    }

    // MARK: - Helpers

    private func makeSUT() -> CityCatalog {
        CityCatalog(cities: [
            City(id: 4, name: "Arizona", countryCode: "US", latitude: 0, longitude: 0),
            City(id: 1, name: "Alabama", countryCode: "US", latitude: 0, longitude: 0),
            City(id: 5, name: "Sydney", countryCode: "AU", latitude: 0, longitude: 0),
            City(id: 2, name: "Albuquerque", countryCode: "US", latitude: 0, longitude: 0),
            City(id: 3, name: "Anaheim", countryCode: "US", latitude: 0, longitude: 0)
        ])
    }

    private func expect(
        _ sut: CityCatalog,
        searching prefix: String,
        keepingFavorites favoriteIDs: Set<Int>,
        toDeliver expectedTitles: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        expect(
            sut.search(prefix: prefix).filter(byFavoriteIDs: favoriteIDs),
            toDeliver: expectedTitles,
            context: "prefijo \"\(prefix)\", favoritos \(favoriteIDs.sorted())",
            file: file,
            line: line
        )
    }

    private func expect(
        _ results: CitySearchResults,
        toDeliver expectedTitles: [String],
        context: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let titles = results.map { "\($0.name), \($0.countryCode)" }

        XCTAssertEqual(titles, expectedTitles, context, file: file, line: line)
    }
}
