//
//  CitiesTests.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import XCTest
import Cities

final class CitiesTests: XCTestCase {

    func test_citiesFramework_isLoadedInTestProcess() {
        XCTAssertNotNil(Bundle(identifier: "com.jfbazan.Cities"))
    }

}
