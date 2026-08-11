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
    private let pageSize: Int
    private var catalog: CityCatalog?
    private var matchingResults: CitySearchResults?
    private var visibleCount: Int
    private var currentPrefix = ""
    private var favoriteIDs: Set<Int>
    private var showsFavoritesOnly = false

    public init(loader: CityCatalogLoader, favoritesStore: FavoritesStore, pageSize: Int = 50) {
        self.loader = loader
        self.favoritesStore = favoritesStore
        self.pageSize = max(1, pageSize)
        visibleCount = self.pageSize
        favoriteIDs = (try? favoritesStore.loadFavoriteIDs()) ?? []
    }

    public func load() async {
        state = .loading
        visibleCount = pageSize
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
        visibleCount = pageSize
        refreshResults()
    }

    public func setFavoritesOnly(_ showsFavoritesOnly: Bool) {
        self.showsFavoritesOnly = showsFavoritesOnly
        visibleCount = pageSize
        refreshResults()
    }

    public func toggleFavorite(cityID: Int) {
        let isFavorite = !favoriteIDs.contains(cityID)

        do {
            try favoritesStore.setFavorite(cityID, isFavorite: isFavorite)
        } catch {
            return
        }

        if isFavorite {
            favoriteIDs.insert(cityID)
        } else {
            favoriteIDs.remove(cityID)
        }
        guard showsFavoritesOnly else { return }
        refreshResults()
    }

    public func showMoreResults(after cityID: Int) {
        guard
            let matchingResults,
            visibleCount < matchingResults.count,
            matchingResults.limited(to: visibleCount).last?.id == cityID
        else { return }

        visibleCount += pageSize
        publishVisibleResults()
    }

    public func isFavorite(_ cityID: Int) -> Bool {
        favoriteIDs.contains(cityID)
    }

    private func refreshResults() {
        guard let catalog else { return }
        let results = catalog.search(prefix: currentPrefix)
        matchingResults = showsFavoritesOnly ? results.filter(byFavoriteIDs: favoriteIDs) : results
        publishVisibleResults()
    }

    private func publishVisibleResults() {
        guard let matchingResults else { return }
        state = .loaded(matchingResults.limited(to: visibleCount))
    }
}
