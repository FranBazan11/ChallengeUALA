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
    func test_makeCityCatalogView_canBeConstructed() {
        _ = CompositionRoot.makeCityCatalogView()
    }

    func test_makeCityCatalogLoader_withoutACatalogInTheConfiguration_usesTheRemoteLoader() {
        let loader = CompositionRoot.makeCityCatalogLoader(configuration: AppConfiguration())

        XCTAssertTrue(loader is RemoteCityCatalogLoader)
    }

    func test_makeCityCatalogLoader_withACatalogInTheConfiguration_deliversThatCatalog() async throws {
        let hurzuf = City(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333)
        let loader = CompositionRoot.makeCityCatalogLoader(
            configuration: AppConfiguration(cityCatalogData: makeCatalogJSON(for: hurzuf))
        )

        let catalog = try await loader.load()

        XCTAssertEqual(catalog.cities, [hurzuf])
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

    private func makeCatalogJSON(for city: City) -> Data {
        let json: [[String: Any]] = [[
            "_id": city.id,
            "name": city.name,
            "country": city.countryCode,
            "coord": ["lat": city.latitude, "lon": city.longitude]
        ]]
        return try! JSONSerialization.data(withJSONObject: json)
    }

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
