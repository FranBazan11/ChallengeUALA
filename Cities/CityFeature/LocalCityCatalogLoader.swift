//
//  LocalCityCatalogLoader.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import Foundation

public struct LocalCityCatalogLoader: CityCatalogLoader {
    private let data: Data

    public init(data: Data) {
        self.data = data
    }

    @concurrent
    public func load() async throws(CityCatalogLoadError) -> CityCatalog {
        do {
            return try CityCatalogMapper.map(data)
        } catch {
            throw .invalidData
        }
    }
}
