//
//  URLSessionHTTPClient.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 07/08/2026.
//

import Foundation

public struct URLSessionHTTPClient: HTTPClient {

    struct UnexpectedValuesRepresentation: Error {}

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnexpectedValuesRepresentation()
        }

        return (data, httpResponse)
    }
}
