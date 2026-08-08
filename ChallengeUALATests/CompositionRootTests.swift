//
//  CompositionRootTests.swift
//  ChallengeUALATests
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import XCTest
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
}
