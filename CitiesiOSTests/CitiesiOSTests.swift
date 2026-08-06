//
//  CitiesiOSTests.swift
//  CitiesiOSTests
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import XCTest
import CitiesiOS

final class CitiesiOSTests: XCTestCase {

    func test_citiesiOSFramework_isLoadedInTestProcess() {
        XCTAssertNotNil(Bundle(identifier: "com.jfbazan.CitiesiOS"))
    }

}
