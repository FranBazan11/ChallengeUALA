//
//  CompositionRootTests.swift
//  ChallengeUALATests
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import XCTest
import Cities
@testable import ChallengeUALA

final class CompositionRootTests: XCTestCase {

    func test_cityCatalogURL_isTheGistFromTheChallenge() {
        XCTAssertEqual(
            CompositionRoot.cityCatalogURL,
            URL(string: "https://gist.githubusercontent.com/hernan-uala/dce8843a8edbe0b0018b32e137bc2b3a/raw/0996accf70cb0ca0e16f9a99e0ee185fafca7af1/cities.json")
        )
    }

    @MainActor
    func test_makeCityListView_canBeConstructed() {
        _ = CompositionRoot.makeCityListView()
    }

    @MainActor
    func test_makeFavoritesStore_remembersFavoritesAcrossAppLaunches() throws {
        let cityID = testSpecificCityID()
        try CompositionRoot.makeFavoritesStore().setFavorite(cityID, isFavorite: true)

        let storeAfterRelaunch = CompositionRoot.makeFavoritesStore()

        XCTAssertTrue(try storeAfterRelaunch.loadFavoriteIDs().contains(cityID))
    }

    @MainActor
    func test_makeFavoritesStore_forgetsFavoritesRemovedInAPreviousLaunch() throws {
        let cityID = testSpecificCityID()
        try CompositionRoot.makeFavoritesStore().setFavorite(cityID, isFavorite: true)

        try CompositionRoot.makeFavoritesStore().setFavorite(cityID, isFavorite: false)

        XCTAssertFalse(try CompositionRoot.makeFavoritesStore().loadFavoriteIDs().contains(cityID))
    }

    // MARK: - Helpers

    @MainActor
    private func testSpecificCityID() -> Int {
        let cityID = 999_999_999
        addTeardownBlock {
            await MainActor.run {
                try? CompositionRoot.makeFavoritesStore().setFavorite(cityID, isFavorite: false)
            }
        }
        return cityID
    }
}
