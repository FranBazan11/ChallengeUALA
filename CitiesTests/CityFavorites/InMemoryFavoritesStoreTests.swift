//
//  InMemoryFavoritesStoreTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

import XCTest
import Cities

@MainActor
final class InMemoryFavoritesStoreTests: XCTestCase {

    func test_loadFavoriteIDs_onEmptyStore_deliversNoFavorites() {
        let sut = makeSUT()

        XCTAssertEqual(sut.loadFavoriteIDs(), [])
    }

    func test_setFavorite_marksCityAsFavorite() {
        let sut = makeSUT()

        sut.setFavorite(707860, isFavorite: true)

        XCTAssertEqual(sut.loadFavoriteIDs(), [707860])
    }

    func test_setFavorite_unmarksAFavoriteCity() {
        let sut = makeSUT()
        sut.setFavorite(707860, isFavorite: true)

        sut.setFavorite(707860, isFavorite: false)

        XCTAssertEqual(sut.loadFavoriteIDs(), [])
    }

    func test_setFavorite_markingTwice_doesNotDuplicateTheFavorite() {
        let sut = makeSUT()
        sut.setFavorite(707860, isFavorite: true)
        sut.setFavorite(707860, isFavorite: true)

        sut.setFavorite(707860, isFavorite: false)

        XCTAssertEqual(sut.loadFavoriteIDs(), [])
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> InMemoryFavoritesStore {
        let sut = InMemoryFavoritesStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
