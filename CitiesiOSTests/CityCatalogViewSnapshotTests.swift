//
//  CityCatalogViewSnapshotTests.swift
//  CitiesiOSTests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest
import Cities
import CitiesiOS

@MainActor
final class CityCatalogViewSnapshotTests: XCTestCase {

    func test_catalogInPortrait_showsTheListOnItsOwnScreen() async {
        let (sut, viewModel) = makeSUT()

        let snapshot = await makeSnapshot(
            of: sut,
            configuration: .iPhone17ProPortrait,
            until: { isLoaded(viewModel) }
        )

        assertSnapshot(snapshot, named: "CITY_CATALOG_PORTRAIT")
    }

    func test_catalogInLandscape_showsTheListAndTheMapAsPanels() async {
        let (sut, viewModel) = makeSUT()

        let snapshot = await makeSnapshot(
            of: sut,
            configuration: .iPhone17ProLandscape,
            until: { isLoaded(viewModel) }
        )

        assertSnapshot(snapshot, named: "CITY_CATALOG_LANDSCAPE")
    }

    // MARK: - Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (view: CityCatalogView, viewModel: CityListViewModel) {
        let loader = CityCatalogLoaderStub(catalog: CityCatalog(cities: makeCities()))
        let favoritesStore = FavoritesStoreStub(favoriteIDs: [3])
        let viewModel = CityListViewModel(loader: loader, favoritesStore: favoritesStore)

        trackForMemoryLeaks(viewModel, file: file, line: line)
        trackForMemoryLeaks(favoritesStore, file: file, line: line)

        return (CityCatalogView(viewModel: viewModel), viewModel)
    }

    private func isLoaded(_ viewModel: CityListViewModel) -> Bool {
        guard case .loaded = viewModel.state else { return false }
        return true
    }

    private func makeCities() -> [City] {
        [
            City(id: 1, name: "Alabama", countryCode: "US", latitude: 32.318231, longitude: -86.902298),
            City(id: 2, name: "Albuquerque", countryCode: "US", latitude: 35.084385, longitude: -106.650421),
            City(id: 3, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333),
            City(id: 4, name: "Sydney", countryCode: "AU", latitude: -33.867851, longitude: 151.207321)
        ]
    }

    private struct CityCatalogLoaderStub: CityCatalogLoader {
        let catalog: CityCatalog

        func load() async throws(CityCatalogLoadError) -> CityCatalog {
            catalog
        }
    }

    @MainActor
    private final class FavoritesStoreStub: FavoritesStore {
        private var favoriteIDs: Set<Int>

        init(favoriteIDs: Set<Int>) {
            self.favoriteIDs = favoriteIDs
        }

        func loadFavoriteIDs() throws -> Set<Int> {
            favoriteIDs
        }

        func setFavorite(_ cityID: Int, isFavorite: Bool) throws {
            if isFavorite {
                favoriteIDs.insert(cityID)
            } else {
                favoriteIDs.remove(cityID)
            }
        }
    }
}
