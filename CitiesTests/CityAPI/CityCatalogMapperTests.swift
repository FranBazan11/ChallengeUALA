//
//  CityCatalogMapperTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import XCTest
import Cities

final class CityCatalogMapperTests: XCTestCase {

    func test_map_withGistFormattedData_deliversTheExpectedCities() throws {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333)
        let denver = makeCity(id: 5419384, name: "Denver", countryCode: "US", latitude: 39.739151, longitude: -104.984703)

        let catalog = try CityCatalogMapper.map(makeCatalogJSON([hurzuf.json, denver.json]))

        XCTAssertEqual(catalog.cities, [hurzuf.model, denver.model])
    }

    func test_map_translatesRemoteFieldNamesIntoDomainFieldNames() throws {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333)

        let city = try XCTUnwrap(CityCatalogMapper.map(makeCatalogJSON([hurzuf.json])).cities.first)

        XCTAssertEqual(
            [city.id.description, city.latitude.description, city.longitude.description],
            ["707860", "44.549999", "34.283333"]
        )
    }

    func test_map_withEmptyList_deliversEmptyCatalog() throws {
        let catalog = try CityCatalogMapper.map(makeCatalogJSON([]))

        XCTAssertEqual(catalog.cities, [])
    }

    func test_map_withDataThatIsNotTheExpectedJSON_throwsInvalidData() {
        expect(toThrowInvalidDataOn: Data("no soy json".utf8))
    }

    func test_map_withEntryMissingARequiredField_throwsInvalidData() {
        var incompleteCityJSON = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333).json
        incompleteCityJSON.removeValue(forKey: "name")

        expect(toThrowInvalidDataOn: makeCatalogJSON([incompleteCityJSON]))
    }

    func test_map_withOneInvalidEntryAmongValidOnes_deliversNoPartialCatalog() {
        let hurzuf = makeCity(id: 707860, name: "Hurzuf", countryCode: "UA", latitude: 44.549999, longitude: 34.283333)
        let sydney = makeCity(id: 2147714, name: "Sydney", countryCode: "AU", latitude: -33.867851, longitude: 151.207321)
        var denverJSON = makeCity(id: 5419384, name: "Denver", countryCode: "US", latitude: 39.739151, longitude: -104.984703).json
        denverJSON.removeValue(forKey: "coord")

        expect(toThrowInvalidDataOn: makeCatalogJSON([hurzuf.json, denverJSON, sydney.json]))
    }

    // MARK: - Helpers

    private func expect(
        toThrowInvalidDataOn data: Data,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try CityCatalogMapper.map(data), file: file, line: line) { error in
            XCTAssertEqual(error as? CityCatalogMapper.Error, .invalidData, file: file, line: line)
        }
    }
}
