//
//  ChallengeUALAUITests.swift
//  ChallengeUALAUITests
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import XCTest

final class ChallengeUALAUITests: XCTestCase {

    @MainActor
    func test_app_launchesInSimulator() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertEqual(app.state, .runningForeground)
    }

}
