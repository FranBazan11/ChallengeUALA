//
//  RemoteCityCatalogLoader.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 07/08/2026.
//

import Foundation

public struct RemoteCityCatalogLoader: Sendable {

    public enum Error: Swift.Error, Equatable, Sendable {
        case connectivity
        case invalidData
        case cancelled
    }

    private let url: URL
    private let client: HTTPClient

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load() async throws(Error) -> CityCatalog {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await client.get(from: url)
        } catch {
            if Task.isCancelled { throw .cancelled }
            throw .connectivity
        }

        if Task.isCancelled { throw .cancelled }

        guard response.statusCode == 200 else { throw .invalidData }

        do {
            return try CityCatalogMapper.map(data)
        } catch {
            throw .invalidData
        }
    }
}
