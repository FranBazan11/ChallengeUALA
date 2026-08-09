//
//  CityListViewModelTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import XCTest
import Cities

@MainActor
final class CityListViewModelTests: XCTestCase {

    func test_init_stateIsLoading() {
        let (sut, _) = makeSUT()

        expect(sut, toBeLoading: true)
    }

    func test_load_onSuccess_deliversLoadedCatalog() async {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333).model
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [hurzuf]))])

        await sut.load()

        expect(sut, toShowCities: [hurzuf])
    }

    func test_load_onConnectivityError_deliversConnectivityMessage() async {
        let (sut, _) = makeSUT(loaderResults: [.failure(.connectivity)])

        await sut.load()

        expect(sut, toFailWithMessage: CityListViewModel.connectivityErrorMessage)
    }

    func test_load_onInvalidDataError_deliversInvalidDataMessage() async {
        let (sut, _) = makeSUT(loaderResults: [.failure(.invalidData)])

        await sut.load()

        expect(sut, toFailWithMessage: CityListViewModel.invalidDataErrorMessage)
    }

    func test_load_onCancelledError_doesNotDeliverFailedState() async {
        let (sut, _) = makeSUT(loaderResults: [.failure(.cancelled)])

        await sut.load()

        expect(sut, toBeLoading: true)
    }

    func test_load_calledAgainAfterFailure_canSucceedOnRetry() async {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333).model
        let (sut, _) = makeSUT(loaderResults: [.failure(.connectivity), .success(CityCatalog(cities: [hurzuf]))])

        await sut.load()
        expect(sut, toFailWithMessage: CityListViewModel.connectivityErrorMessage)

        await sut.load()
        expect(sut, toShowCities: [hurzuf])
    }

    func test_search_beforeCatalogLoads_doesNotChangeState() {
        let (sut, _) = makeSUT()

        sut.search(prefix: "al")

        expect(sut, toBeLoading: true)
    }

    func test_search_afterCatalogLoads_filtersLoadedCatalog() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))])
        await sut.load()

        sut.search(prefix: "al")

        expect(sut, toShowCities: [alabama])
    }

    func test_load_appliesPrefixSetBeforeLoadCompletes() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))])

        sut.search(prefix: "syd")
        await sut.load()

        expect(sut, toShowCities: [sydney])
    }

    func test_init_readsFavoriteIDsFromTheStore() {
        let (sut, _) = makeSUT(favoriteIDs: [1])

        XCTAssertTrue(sut.isFavorite(1))
        XCTAssertFalse(sut.isFavorite(2))
    }

    func test_toggleFavorite_onNonFavoriteCity_marksItAsFavorite() {
        let (sut, store) = makeSUT()

        sut.toggleFavorite(cityID: 1)

        XCTAssertTrue(sut.isFavorite(1))
        XCTAssertEqual(store.messages, [.setFavorite(cityID: 1, isFavorite: true)])
    }

    func test_toggleFavorite_onFavoriteCity_unmarksIt() {
        let (sut, store) = makeSUT(favoriteIDs: [1])

        sut.toggleFavorite(cityID: 1)

        XCTAssertFalse(sut.isFavorite(1))
        XCTAssertEqual(store.messages, [.setFavorite(cityID: 1, isFavorite: false)])
    }

    func test_toggleFavorite_twiceOnTheSameCity_leavesItAsItStarted() {
        let (sut, store) = makeSUT()

        sut.toggleFavorite(cityID: 1)
        sut.toggleFavorite(cityID: 1)

        XCTAssertFalse(sut.isFavorite(1))
        XCTAssertEqual(store.messages, [
            .setFavorite(cityID: 1, isFavorite: true),
            .setFavorite(cityID: 1, isFavorite: false)
        ])
    }

    func test_toggleFavorite_beforeCatalogLoads_doesNotChangeState() {
        let (sut, _) = makeSUT()

        sut.toggleFavorite(cityID: 1)

        expect(sut, toBeLoading: true)
    }

    func test_setFavoritesOnly_withoutPrefix_showsOnlyFavoriteCities() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))], favoriteIDs: [sydney.id])
        await sut.load()

        sut.setFavoritesOnly(true)

        expect(sut, toShowCities: [sydney])
    }

    func test_setFavoritesOnly_combinedWithAPrefix_showsTheIntersection() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(
            loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))],
            favoriteIDs: [alabama.id, sydney.id]
        )
        await sut.load()

        sut.setFavoritesOnly(true)
        sut.search(prefix: "al")

        expect(sut, toShowCities: [alabama])
    }

    func test_setFavoritesOnly_withoutAnyFavorite_showsNoCities() async {
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [makeAlabama(), makeSydney()]))])
        await sut.load()

        sut.setFavoritesOnly(true)

        expect(sut, toShowCities: [])
    }

    func test_setFavoritesOnly_turnedOff_showsTheWholeCatalogAgain() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))], favoriteIDs: [sydney.id])
        await sut.load()
        sut.setFavoritesOnly(true)

        sut.setFavoritesOnly(false)

        expect(sut, toShowCities: [alabama, sydney])
    }

    func test_setFavoritesOnly_turnedOff_keepsTheCurrentPrefixApplied() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))], favoriteIDs: [sydney.id])
        await sut.load()
        sut.search(prefix: "al")
        sut.setFavoritesOnly(true)

        sut.setFavoritesOnly(false)

        expect(sut, toShowCities: [alabama])
    }

    func test_toggleFavorite_whileShowingFavoritesOnly_updatesTheVisibleList() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))], favoriteIDs: [sydney.id])
        await sut.load()
        sut.setFavoritesOnly(true)

        sut.toggleFavorite(cityID: alabama.id)

        expect(sut, toShowCities: [alabama, sydney])
    }

    func test_load_appliesFavoritesOnlyFilterSetBeforeLoadCompletes() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))], favoriteIDs: [sydney.id])

        sut.setFavoritesOnly(true)
        await sut.load()

        expect(sut, toShowCities: [sydney])
    }

    // MARK: - Helpers

    private func makeSUT(
        loaderResults: [Result<CityCatalog, CityCatalogLoadError>] = [.success(CityCatalog(cities: []))],
        favoriteIDs: Set<Int> = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: CityListViewModel, favoritesStore: FavoritesStoreSpy) {
        let loader = CityCatalogLoaderStub(results: loaderResults)
        let favoritesStore = FavoritesStoreSpy(favoriteIDs: favoriteIDs)
        let sut = CityListViewModel(loader: loader, favoritesStore: favoritesStore)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(favoritesStore, file: file, line: line)
        return (sut, favoritesStore)
    }

    private func makeAlabama() -> City {
        makeCity(id: 1, name: "Alabama", countryCode: "US", latitude: 0, longitude: 0).model
    }

    private func makeSydney() -> City {
        makeCity(id: 2, name: "Sydney", countryCode: "AU", latitude: 0, longitude: 0).model
    }

    @MainActor
    private final class FavoritesStoreSpy: FavoritesStore {
        enum Message: Equatable {
            case setFavorite(cityID: Int, isFavorite: Bool)
        }

        private(set) var messages: [Message] = []
        private var favoriteIDs: Set<Int>

        init(favoriteIDs: Set<Int>) {
            self.favoriteIDs = favoriteIDs
        }

        func loadFavoriteIDs() -> Set<Int> {
            favoriteIDs
        }

        func setFavorite(_ cityID: Int, isFavorite: Bool) {
            messages.append(.setFavorite(cityID: cityID, isFavorite: isFavorite))
            if isFavorite {
                favoriteIDs.insert(cityID)
            } else {
                favoriteIDs.remove(cityID)
            }
        }
    }

    private func expect(
        _ sut: CityListViewModel,
        toBeLoading expectedLoading: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch sut.state {
        case .loading:
            XCTAssertTrue(expectedLoading, "Expected not to be loading", file: file, line: line)
        default:
            XCTAssertFalse(expectedLoading, "Expected to be loading, got \(sut.state) instead", file: file, line: line)
        }
    }

    private func expect(
        _ sut: CityListViewModel,
        toShowCities expectedCities: [City],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch sut.state {
        case let .loaded(results):
            XCTAssertEqual(Array(results), expectedCities, file: file, line: line)
        default:
            XCTFail("Expected loaded state with \(expectedCities), got \(sut.state) instead", file: file, line: line)
        }
    }

    private func expect(
        _ sut: CityListViewModel,
        toFailWithMessage expectedMessage: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        switch sut.state {
        case let .failed(message):
            XCTAssertEqual(message, expectedMessage, file: file, line: line)
        default:
            XCTFail("Expected failed state with message \(expectedMessage), got \(sut.state) instead", file: file, line: line)
        }
    }

    private actor CityCatalogLoaderStub: CityCatalogLoader {
        private var results: [Result<CityCatalog, CityCatalogLoadError>]

        init(results: [Result<CityCatalog, CityCatalogLoadError>]) {
            self.results = results
        }

        func load() async throws(CityCatalogLoadError) -> CityCatalog {
            switch results.removeFirst() {
            case let .success(catalog):
                return catalog
            case let .failure(error):
                throw error
            }
        }
    }
}
