//
//  LocalCityCatalogLoaderTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest
import Cities

final class LocalCityCatalogLoaderTests: XCTestCase {

    func test_load_withValidData_deliversTheMappedCatalog() async throws {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333)
        let sut = makeSUT(data: makeCatalogJSON([hurzuf.json]))

        let catalog = try await sut.load()

        XCTAssertEqual(catalog.cities, [hurzuf.model])
    }

    func test_load_withAnEmptyList_deliversAnEmptyCatalog() async throws {
        let sut = makeSUT(data: makeCatalogJSON([]))

        let catalog = try await sut.load()

        XCTAssertEqual(catalog.cities, [])
    }

    func test_load_withInvalidData_deliversInvalidDataError() async {
        let sut = makeSUT(data: anyData())

        do throws(CityCatalogLoadError) {
            _ = try await sut.load()
            XCTFail("Expected the load to fail with invalid data")
        } catch {
            XCTAssertEqual(error, .invalidData)
        }
    }

    func test_load_twice_deliversTheSameCatalogWithoutConsumingTheData() async throws {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333)
        let sut = makeSUT(data: makeCatalogJSON([hurzuf.json]))

        _ = try await sut.load()
        let secondCatalog = try await sut.load()

        XCTAssertEqual(secondCatalog.cities, [hurzuf.model])
    }

    // MARK: - Helpers

    private func makeSUT(data: Data) -> LocalCityCatalogLoader {
        LocalCityCatalogLoader(data: data)
    }
}
