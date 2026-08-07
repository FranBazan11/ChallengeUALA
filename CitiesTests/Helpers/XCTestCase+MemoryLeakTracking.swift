//
//  XCTestCase+MemoryLeakTracking.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 07/08/2026.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks<Instance: AnyObject & Sendable>(_ instance: Instance, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "La instancia deberia haber sido liberada. Posible memory leak.", file: file, line: line)
        }
    }
}
