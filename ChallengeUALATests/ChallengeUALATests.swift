//
//  ChallengeUALATests.swift
//  ChallengeUALATests
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import XCTest
@testable import ChallengeUALA

final class ChallengeUALATests: XCTestCase {

    func test_appBundle_hasExpectedBundleIdentifier() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.jfbazan.ChallengeUALA")
    }

}
