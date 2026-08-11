//
//  CityListViewModelTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import XCTest
import Observation
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

    func test_toggleFavorite_whenTheStoreFailsToPersist_leavesTheCityNotFavorite() {
        let (sut, _) = makeSUT(setError: anyNSError())

        sut.toggleFavorite(cityID: 1)

        XCTAssertFalse(sut.isFavorite(1))
    }

    func test_toggleFavorite_whenTheStoreFailsToPersist_leavesAFavoriteCityFavorite() {
        let (sut, _) = makeSUT(favoriteIDs: [1], setError: anyNSError())

        sut.toggleFavorite(cityID: 1)

        XCTAssertTrue(sut.isFavorite(1))
    }

    func test_toggleFavorite_whenTheStoreFailsToPersist_keepsTheVisibleCitiesUntouched() async {
        let (alabama, sydney) = (makeAlabama(), makeSydney())
        let (sut, _) = makeSUT(
            loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))],
            favoriteIDs: [alabama.id, sydney.id],
            setError: anyNSError()
        )
        await sut.load()
        sut.setFavoritesOnly(true)

        sut.toggleFavorite(cityID: alabama.id)

        expect(sut, toShowCities: [alabama, sydney])
    }

    func test_init_whenTheStoreFailsToLoad_startsWithNoFavorites() {
        let (sut, _) = makeSUT(favoriteIDs: [1], loadError: anyNSError())

        XCTAssertFalse(sut.isFavorite(1))
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

    func test_load_withMoreCitiesThanThePageSize_showsOnlyTheFirstPage() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 2)

        await sut.load()

        expect(sut, toShowCities: Array(cities.prefix(2)))
    }

    func test_load_withANonPositivePageSize_stillShowsAFirstPage() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 0)

        await sut.load()

        expect(sut, toShowCities: Array(cities.prefix(1)))
    }

    func test_showMoreResults_withANegativePageSize_canStillGrowTheVisibleWindow() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: -1)
        await sut.load()

        sut.showMoreResults(after: cities[0].id)

        expect(sut, toShowCities: Array(cities.prefix(2)))
    }

    func test_showMoreResults_afterTheLastVisibleCity_showsTheNextPage() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 2)
        await sut.load()

        sut.showMoreResults(after: cities[1].id)

        expect(sut, toShowCities: cities)
    }

    func test_showMoreResults_afterACityThatIsNotTheLastVisible_showsTheSamePage() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 2)
        await sut.load()

        sut.showMoreResults(after: cities[0].id)

        expect(sut, toShowCities: Array(cities.prefix(2)))
    }

    func test_showMoreResults_withEveryResultAlreadyVisible_showsTheSameCities() async {
        let cities = makeCities(2)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 2)
        await sut.load()

        sut.showMoreResults(after: cities[1].id)

        expect(sut, toShowCities: cities)
    }

    func test_search_afterShowingMoreResults_goesBackToTheFirstPage() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 2)
        await sut.load()
        sut.showMoreResults(after: cities[1].id)

        sut.search(prefix: "City")

        expect(sut, toShowCities: Array(cities.prefix(2)))
    }

    func test_setFavoritesOnly_afterShowingMoreResults_goesBackToTheFirstPage() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(
            loaderResults: [.success(CityCatalog(cities: cities))],
            favoriteIDs: Set(cities.map(\.id)),
            pageSize: 2
        )
        await sut.load()
        sut.showMoreResults(after: cities[1].id)

        sut.setFavoritesOnly(true)

        expect(sut, toShowCities: Array(cities.prefix(2)))
    }

    func test_toggleFavorite_withTheFavoritesFilterOff_keepsTheVisibleCitiesUntouched() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 2)
        await sut.load()
        sut.showMoreResults(after: cities[1].id)

        sut.toggleFavorite(cityID: cities[0].id)

        expect(sut, toShowCities: cities)
    }

    func test_toggleFavorite_withTheFavoritesFilterOn_keepsTheVisibleWindowWhileUpdatingTheList() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(
            loaderResults: [.success(CityCatalog(cities: cities))],
            favoriteIDs: Set(cities.map(\.id)),
            pageSize: 2
        )
        await sut.load()
        sut.setFavoritesOnly(true)
        sut.showMoreResults(after: cities[1].id)

        sut.toggleFavorite(cityID: cities[3].id)

        expect(sut, toShowCities: Array(cities.prefix(3)))
    }

    func test_load_doesNotRunTheLoaderOnTheMainThread() async {
        let recorder = MainThreadRecorder()
        let sut = makeSUT(loaderRecordingInto: recorder)

        await sut.load()

        let loadedOnMainThread = await recorder.loadedOnMainThread
        XCTAssertEqual(loadedOnMainThread, false)
    }

    func test_toggleFavorite_withTheFavoritesFilterOff_doesNotRepublishTheList() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(loaderResults: [.success(CityCatalog(cities: cities))], pageSize: 2)
        await sut.load()
        sut.showMoreResults(after: cities[1].id)

        let didPublish = publishesState(sut) {
            sut.toggleFavorite(cityID: cities[0].id)
        }

        XCTAssertFalse(didPublish)
    }

    func test_toggleFavorite_withTheFavoritesFilterOn_republishesTheList() async {
        let cities = makeCities(4)
        let (sut, _) = makeSUT(
            loaderResults: [.success(CityCatalog(cities: cities))],
            favoriteIDs: Set(cities.map(\.id)),
            pageSize: 2
        )
        await sut.load()
        sut.setFavoritesOnly(true)

        let didPublish = publishesState(sut) {
            sut.toggleFavorite(cityID: cities[0].id)
        }

        XCTAssertTrue(didPublish)
    }

    // MARK: - Helpers

    private func makeSUT(
        loaderResults: [Result<CityCatalog, CityCatalogLoadError>] = [.success(CityCatalog(cities: []))],
        favoriteIDs: Set<Int> = [],
        loadError: Error? = nil,
        setError: Error? = nil,
        pageSize: Int = 50,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: CityListViewModel, favoritesStore: FavoritesStoreSpy) {
        let loader = CityCatalogLoaderStub(results: loaderResults)
        let favoritesStore = FavoritesStoreSpy(favoriteIDs: favoriteIDs, loadError: loadError, setError: setError)
        let sut = CityListViewModel(loader: loader, favoritesStore: favoritesStore, pageSize: pageSize)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(favoritesStore, file: file, line: line)
        return (sut, favoritesStore)
    }

    private func makeSUT(
        loaderRecordingInto recorder: MainThreadRecorder,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CityListViewModel {
        let loader = MainThreadRecordingCityCatalogLoader(recorder: recorder)
        let favoritesStore = FavoritesStoreSpy(favoriteIDs: [])
        let sut = CityListViewModel(loader: loader, favoritesStore: favoritesStore)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(favoritesStore, file: file, line: line)
        trackForMemoryLeaks(recorder, file: file, line: line)
        return sut
    }

    private func publishesState(_ sut: CityListViewModel, when action: () -> Void) -> Bool {
        let recorder = StatePublicationRecorder()
        withObservationTracking {
            _ = sut.state
        } onChange: {
            MainActor.assumeIsolated { recorder.didPublish = true }
        }

        action()

        return recorder.didPublish
    }

    private func makeAlabama() -> City {
        makeCity(id: 1, name: "Alabama", countryCode: "US", latitude: 0, longitude: 0).model
    }

    private func makeSydney() -> City {
        makeCity(id: 2, name: "Sydney", countryCode: "AU", latitude: 0, longitude: 0).model
    }

    private func makeCities(_ count: Int) -> [City] {
        (1...count).map { makeCity(id: $0, name: "City\($0)", countryCode: "US", latitude: 0, longitude: 0).model }
    }

    @MainActor
    private final class StatePublicationRecorder {
        var didPublish = false
    }

    @MainActor
    private final class FavoritesStoreSpy: FavoritesStore {
        enum Message: Equatable {
            case setFavorite(cityID: Int, isFavorite: Bool)
        }

        private(set) var messages: [Message] = []
        private var favoriteIDs: Set<Int>
        private let loadError: Error?
        private let setError: Error?

        init(favoriteIDs: Set<Int>, loadError: Error? = nil, setError: Error? = nil) {
            self.favoriteIDs = favoriteIDs
            self.loadError = loadError
            self.setError = setError
        }

        func loadFavoriteIDs() throws -> Set<Int> {
            if let loadError { throw loadError }
            return favoriteIDs
        }

        func setFavorite(_ cityID: Int, isFavorite: Bool) throws {
            messages.append(.setFavorite(cityID: cityID, isFavorite: isFavorite))
            if let setError { throw setError }
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

    private actor MainThreadRecorder {
        private(set) var loadedOnMainThread: Bool?

        func record(mainThread: Bool) {
            loadedOnMainThread = mainThread
        }
    }

    private struct MainThreadRecordingCityCatalogLoader: CityCatalogLoader {
        let recorder: MainThreadRecorder

        func load() async throws(CityCatalogLoadError) -> CityCatalog {
            let isMainThread = isMainThreadSync()
            await recorder.record(mainThread: isMainThread)
            return CityCatalog(cities: [])
        }
    }
}

private nonisolated func isMainThreadSync() -> Bool {
    Thread.isMainThread
}
