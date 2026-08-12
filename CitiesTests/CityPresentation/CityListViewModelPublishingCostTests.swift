//
//  CityListViewModelPublishingCostTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 12/08/2026.
//

import XCTest
import Cities

@MainActor
final class CityListViewModelPublishingCostTests: XCTestCase {

    func test_publishingTheVisibleWindow_costDoesNotScaleWithItsSize() async {
        let catalog = CityCatalog(cities: makeLargeCityList())

        let smallWindowSUT = makeSUT(catalog: catalog, pageSize: smallWindowSize)
        await smallWindowSUT.load()
        let smallWindowDuration = durationOfPublishing(smallWindowSUT, repeated: publishRepetitions)

        let largeWindowSUT = makeSUT(catalog: catalog, pageSize: largeCityListSize)
        await largeWindowSUT.load()
        let largeWindowDuration = durationOfPublishing(largeWindowSUT, repeated: publishRepetitions)

        XCTAssertLessThan(
            largeWindowDuration,
            smallWindowDuration * maximumAcceptableCostRatio,
            "Publicar una ventana de \(largeCityListSize) elementos tardó \(largeWindowDuration)s, "
                + "\(largeWindowDuration / smallWindowDuration)x el costo de publicar una ventana de "
                + "\(smallWindowSize) (\(smallWindowDuration)s). El publish no puede escalar con el tamaño de la ventana."
        )
    }

    // MARK: - Helpers

    private let smallWindowSize = 50
    private let publishRepetitions = 20
    private let maximumAcceptableCostRatio = 20.0

    private func makeSUT(
        catalog: CityCatalog,
        pageSize: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CityListViewModel {
        let loader = CityCatalogLoaderStub(results: [.success(catalog)])
        let favoritesStore = InMemoryFavoritesStore()
        let sut = CityListViewModel(loader: loader, favoritesStore: favoritesStore, pageSize: pageSize)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(favoritesStore, file: file, line: line)
        return sut
    }

    private func durationOfPublishing(_ sut: CityListViewModel, repeated times: Int) -> TimeInterval {
        sut.search(prefix: "")

        let start = Date()
        for _ in 0..<times {
            sut.search(prefix: "")
        }
        return Date().timeIntervalSince(start)
    }
}
