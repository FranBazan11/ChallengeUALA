//
//  AppConfigurationTests.swift
//  ChallengeUALATests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest
@testable import ChallengeUALA

final class AppConfigurationTests: XCTestCase {

    func test_init_withAnEmptyEnvironment_hasNoCityCatalogData() {
        let sut = makeSUT(environment: [:])

        XCTAssertNil(sut.cityCatalogData)
    }

    func test_init_withUnrelatedEnvironmentEntries_hasNoCityCatalogData() {
        let sut = makeSUT(environment: ["SOME_OTHER_KEY": "some value"])

        XCTAssertNil(sut.cityCatalogData)
    }

    func test_init_withTheCityCatalogKey_carriesItsDataAsUTF8() {
        let json = #"[{"_id":1}]"#
        let sut = makeSUT(environment: [AppConfiguration.cityCatalogJSONKey: json])

        XCTAssertEqual(sut.cityCatalogData, Data(json.utf8))
    }

    func test_init_withAnEmptyCityCatalogValue_hasNoCityCatalogData() {
        let sut = makeSUT(environment: [AppConfiguration.cityCatalogJSONKey: ""])

        XCTAssertNil(sut.cityCatalogData)
    }

    // MARK: - Helpers

    private func makeSUT(environment: [String: String]) -> AppConfiguration {
        AppConfiguration(environment: environment)
    }
}
