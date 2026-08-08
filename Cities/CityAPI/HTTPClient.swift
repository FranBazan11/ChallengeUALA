//
//  HTTPClient.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 07/08/2026.
//

import Foundation

public protocol HTTPClient: Sendable {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}
