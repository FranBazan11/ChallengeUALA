//
//  SwiftDataFavoritesStoreTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

import XCTest
import Cities

@MainActor
final class SwiftDataFavoritesStoreTests: XCTestCase {

    func test_loadFavoriteIDs_onEmptyStore_deliversNoFavorites() throws {
        let sut = makeSUT()

        XCTAssertEqual(try sut.loadFavoriteIDs(), [])
    }

    func test_setFavorite_marksCityAsFavorite() throws {
        let sut = makeSUT()

        try sut.setFavorite(707860, isFavorite: true)

        XCTAssertEqual(try sut.loadFavoriteIDs(), [707860])
    }

    func test_setFavorite_unmarksAFavoriteCity() throws {
        let sut = makeSUT()
        try sut.setFavorite(707860, isFavorite: true)

        try sut.setFavorite(707860, isFavorite: false)

        XCTAssertEqual(try sut.loadFavoriteIDs(), [])
    }

    func test_setFavorite_unmarkingANonFavoriteCity_hasNoEffect() throws {
        let sut = makeSUT()

        try sut.setFavorite(707860, isFavorite: false)

        XCTAssertEqual(try sut.loadFavoriteIDs(), [])
    }

    func test_setFavorite_markingTwice_doesNotDuplicateTheFavorite() throws {
        let sut = makeSUT()
        try sut.setFavorite(707860, isFavorite: true)
        try sut.setFavorite(707860, isFavorite: true)

        try sut.setFavorite(707860, isFavorite: false)

        XCTAssertEqual(try sut.loadFavoriteIDs(), [])
    }

    func test_setFavorite_keepsOtherFavoritesUntouched() throws {
        let sut = makeSUT()
        try sut.setFavorite(1, isFavorite: true)
        try sut.setFavorite(2, isFavorite: true)

        try sut.setFavorite(1, isFavorite: false)

        XCTAssertEqual(try sut.loadFavoriteIDs(), [2])
    }

    func test_loadFavoriteIDs_onASeparateStoreInstance_deliversPreviouslySavedFavorites() throws {
        let storeURL = testSpecificStoreURL()
        let storeToWrite = makeSUT(storeURL: storeURL)
        try storeToWrite.setFavorite(707860, isFavorite: true)

        let storeToRead = makeSUT(storeURL: storeURL)

        XCTAssertEqual(try storeToRead.loadFavoriteIDs(), [707860])
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> SwiftDataFavoritesStore {
        makeSUT(storeURL: testSpecificStoreURL(), file: file, line: line)
    }

    private func makeSUT(
        storeURL: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SwiftDataFavoritesStore {
        let sut = try! SwiftDataFavoritesStore(storeURL: storeURL)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func testSpecificStoreURL() -> URL {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(type(of: self))-\(UUID()).store")
        addTeardownBlock { removeStoreArtifacts(at: storeURL) }
        return storeURL
    }
}

private func removeStoreArtifacts(at storeURL: URL) {
    for suffix in ["", "-wal", "-shm"] {
        let url = URL(fileURLWithPath: storeURL.path + suffix)
        try? FileManager.default.removeItem(at: url)
    }
}
