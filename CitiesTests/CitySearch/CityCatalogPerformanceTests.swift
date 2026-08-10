//
//  CityCatalogPerformanceTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import XCTest
import Cities

final class CityCatalogPerformanceTests: XCTestCase {

    func test_buildingTheIndex_over200kCities() {
        let cities = makeLargeCityList()

        measure {
            _ = CityCatalog(cities: cities)
        }
    }

    func test_searching_over200kCities_whileTypingCharacterByCharacter() {
        let catalog = CityCatalog(cities: makeLargeCityList())
        let typedPrefixes = ["s", "sy", "syd", "sydn", "sydne", "sydney"]

        measure {
            for prefix in typedPrefixes {
                let results = catalog.search(prefix: prefix)
                _ = results.prefix(visibleRowsOnScreen).map(\.name)
            }
        }
    }

    func test_filteringFavorites_withoutPrefix_over200kCities() {
        let catalog = CityCatalog(cities: makeLargeCityList())
        let favoriteIDs = Set((0..<favoriteCount).map { $0 * (catalogSize / favoriteCount) })

        measure {
            let results = catalog.search(prefix: "").filter(byFavoriteIDs: favoriteIDs)
            _ = results.prefix(visibleRowsOnScreen).map(\.name)
        }
    }

    // MARK: - Helpers

    private let catalogSize = 200_000
    private let favoriteCount = 20
    private let visibleRowsOnScreen = 50

    private func makeLargeCityList() -> [City] {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

        return (0..<catalogSize).map { index in
            let name = String([
                alphabet[index % 26],
                alphabet[(index / 26) % 26],
                alphabet[(index / 676) % 26],
                alphabet[(index / 17_576) % 26]
            ])

            return City(
                id: index,
                name: name + String(index),
                countryCode: "US",
                latitude: 0,
                longitude: 0
            )
        }
    }
}
