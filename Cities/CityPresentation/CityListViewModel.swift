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
    private let favoritesStore: FavoritesStore
    private var catalog: CityCatalog?
    private var currentPrefix = ""
    private var favoriteIDs: Set<Int>
    private var showsFavoritesOnly = false

    public init(loader: CityCatalogLoader, favoritesStore: FavoritesStore) {
        self.loader = loader
        self.favoritesStore = favoritesStore
        favoriteIDs = favoritesStore.loadFavoriteIDs()
    }

    public func load() async {
        state = .loading
        do throws(CityCatalogLoadError) {
            catalog = try await loader.load()
            refreshResults()
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
        refreshResults()
    }

    public func setFavoritesOnly(_ showsFavoritesOnly: Bool) {
        self.showsFavoritesOnly = showsFavoritesOnly
        refreshResults()
    }

    public func toggleFavorite(cityID: Int) {
        let isFavorite = !favoriteIDs.contains(cityID)
        favoritesStore.setFavorite(cityID, isFavorite: isFavorite)
        if isFavorite {
            favoriteIDs.insert(cityID)
        } else {
            favoriteIDs.remove(cityID)
        }
        refreshResults()
    }

    public func isFavorite(_ cityID: Int) -> Bool {
        favoriteIDs.contains(cityID)
    }

    private func refreshResults() {
        guard let catalog else { return }
        let results = catalog.search(prefix: currentPrefix)
        state = .loaded(showsFavoritesOnly ? results.filter(byFavoriteIDs: favoriteIDs) : results)
    }
}
