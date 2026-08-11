//
//  SnapshotInfrastructureTests.swift
//  CitiesiOSTests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import XCTest
import SwiftUI

@MainActor
final class SnapshotInfrastructureTests: XCTestCase {

    func test_snapshot_rendersAListAtTheConfiguredSize() async {
        let snapshot = await makeSnapshot(of: makeSUT(), configuration: .iPhone17ProPortrait)

        XCTAssertEqual(snapshot.size, SnapshotConfiguration.iPhone17ProPortrait.size)
    }

    func test_snapshot_rendersAListAtTheConfiguredScale() async {
        let snapshot = await makeSnapshot(of: makeSUT(), configuration: .iPhone17ProPortrait)

        XCTAssertEqual(snapshot.scale, SnapshotConfiguration.iPhone17ProPortrait.displayScale)
    }

    func test_snapshot_matchesItsRecordedReference() async {
        let snapshot = await makeSnapshot(of: makeSUT(), configuration: .iPhone17ProPortrait)

        assertSnapshot(snapshot, named: "SNAPSHOT_INFRASTRUCTURE_LIST")
    }

    // MARK: - Helpers

    private func makeSUT() -> some View {
        List(1...3, id: \.self) { row in
            Text("Fila \(row)")
        }
        .listStyle(.plain)
    }
}
