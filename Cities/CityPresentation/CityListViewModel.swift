//
//  CityListViewModel.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import Observation

@Observable
@MainActor
public final class CityListViewModel: Sendable {

    @frozen
    public enum State {
        case loading
        case loaded(CitySearchResults)
        case failed(message: String)
    }

    public static let connectivityErrorMessage = "No pudimos conectarnos. Revisá tu conexión e intentá de nuevo."
    public static let invalidDataErrorMessage = "Ocurrió un error inesperado. Intentá de nuevo."

    public private(set) var state: State = .loading

    private let loader: CityCatalogLoader
    private var catalog: CityCatalog?
    private var currentPrefix = ""

    public init(loader: CityCatalogLoader) {
        self.loader = loader
    }

    public func load() async {
        state = .loading
        do throws(CityCatalogLoadError) {
            let loadedCatalog = try await loader.load()
            catalog = loadedCatalog
            state = .loaded(loadedCatalog.search(prefix: currentPrefix))
        } catch {
            switch error {
            case .cancelled:
                break
            case .connectivity:
                state = .failed(message: Self.connectivityErrorMessage)
            case .invalidData:
                state = .failed(message: Self.invalidDataErrorMessage)
            }
        }
    }

    public func search(prefix: String) {
        currentPrefix = prefix
        guard let catalog else { return }
        state = .loaded(catalog.search(prefix: prefix))
    }
}
