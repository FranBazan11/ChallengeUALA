//
//  CityCatalogLoader.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

public enum CityCatalogLoadError: Error, Equatable, Sendable {
    case connectivity
    case invalidData
    case cancelled
}

public protocol CityCatalogLoader: Sendable {
    func load() async throws(CityCatalogLoadError) -> CityCatalog
}
