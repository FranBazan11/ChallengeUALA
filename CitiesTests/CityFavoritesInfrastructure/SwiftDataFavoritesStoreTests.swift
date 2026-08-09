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

    func test_setFavorite_unmarkingANonFavoriteCity_hasNoEffect() {
        let sut = makeSUT()

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

    func test_setFavorite_keepsOtherFavoritesUntouched() {
        let sut = makeSUT()
        sut.setFavorite(1, isFavorite: true)
        sut.setFavorite(2, isFavorite: true)

        sut.setFavorite(1, isFavorite: false)

        XCTAssertEqual(sut.loadFavoriteIDs(), [2])
    }

    func test_loadFavoriteIDs_onASeparateStoreInstance_deliversPreviouslySavedFavorites() {
        let storeURL = testSpecificStoreURL()
        let storeToWrite = makeSUT(storeURL: storeURL)
        storeToWrite.setFavorite(707860, isFavorite: true)

        let storeToRead = makeSUT(storeURL: storeURL)

        XCTAssertEqual(storeToRead.loadFavoriteIDs(), [707860])
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
