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
        let sut = makeSUT()

        expect(sut, toBeLoading: true)
    }

    func test_load_onSuccess_deliversLoadedCatalog() async {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333).model
        let sut = makeSUT(loaderResults: [.success(CityCatalog(cities: [hurzuf]))])

        await sut.load()

        expect(sut, toShowCities: [hurzuf])
    }

    func test_load_onConnectivityError_deliversConnectivityMessage() async {
        let sut = makeSUT(loaderResults: [.failure(.connectivity)])

        await sut.load()

        expect(sut, toFailWithMessage: CityListViewModel.connectivityErrorMessage)
    }

    func test_load_onInvalidDataError_deliversInvalidDataMessage() async {
        let sut = makeSUT(loaderResults: [.failure(.invalidData)])

        await sut.load()

        expect(sut, toFailWithMessage: CityListViewModel.invalidDataErrorMessage)
    }

    func test_load_onCancelledError_doesNotDeliverFailedState() async {
        let sut = makeSUT(loaderResults: [.failure(.cancelled)])

        await sut.load()

        expect(sut, toBeLoading: true)
    }

    func test_load_calledAgainAfterFailure_canSucceedOnRetry() async {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333).model
        let sut = makeSUT(loaderResults: [.failure(.connectivity), .success(CityCatalog(cities: [hurzuf]))])

        await sut.load()
        expect(sut, toFailWithMessage: CityListViewModel.connectivityErrorMessage)

        await sut.load()
        expect(sut, toShowCities: [hurzuf])
    }

    func test_search_beforeCatalogLoads_doesNotChangeState() {
        let sut = makeSUT()

        sut.search(prefix: "al")

        expect(sut, toBeLoading: true)
    }

    func test_search_afterCatalogLoads_filtersLoadedCatalog() async {
        let alabama = makeCity(id: 1, name: "Alabama", countryCode: "US", latitude: 0, longitude: 0).model
        let sydney = makeCity(id: 2, name: "Sydney", countryCode: "AU", latitude: 0, longitude: 0).model
        let sut = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))])
        await sut.load()

        sut.search(prefix: "al")

        expect(sut, toShowCities: [alabama])
    }

    func test_load_appliesPrefixSetBeforeLoadCompletes() async {
        let alabama = makeCity(id: 1, name: "Alabama", countryCode: "US", latitude: 0, longitude: 0).model
        let sydney = makeCity(id: 2, name: "Sydney", countryCode: "AU", latitude: 0, longitude: 0).model
        let sut = makeSUT(loaderResults: [.success(CityCatalog(cities: [alabama, sydney]))])

        sut.search(prefix: "syd")
        await sut.load()

        expect(sut, toShowCities: [sydney])
    }

    // MARK: - Helpers

    private func makeSUT(
        loaderResults: [Result<CityCatalog, CityCatalogLoadError>] = [.success(CityCatalog(cities: []))],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CityListViewModel {
        let loader = CityCatalogLoaderStub(results: loaderResults)
        let sut = CityListViewModel(loader: loader)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
