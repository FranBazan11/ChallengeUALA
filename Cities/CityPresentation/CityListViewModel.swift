//
//  CityListViewModel.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import Foundation
import Observation

@Observable
@MainActor
public final class CityListViewModel: Sendable {

    @frozen
    public enum State {
        case loading
        case loaded(CityCellViewModels)
        case failed(message: String)
    }

    public static let connectivityErrorMessage = "No pudimos conectarnos. Revisá tu conexión e intentá de nuevo."
    public static let invalidDataErrorMessage = "Ocurrió un error inesperado. Intentá de nuevo."

    public private(set) var state: State = .loading
    public private(set) var searchPrefix = ""
    public private(set) var showsFavoritesOnly = false

    private let loader: CityCatalogLoader
    private let favoritesStore: FavoritesStore
    private let pageSize: Int
    private let locale: Locale
    private var catalog: CityCatalog?
    private var matchingResults: CitySearchResults?
    private var visibleCount: Int
    private var favoriteIDs: Set<Int>
    private var selectedCity: City?

    public init(
        loader: CityCatalogLoader,
        favoritesStore: FavoritesStore,
        pageSize: Int = 50,
        locale: Locale = .current
    ) {
        self.loader = loader
        self.favoritesStore = favoritesStore
        self.pageSize = max(1, pageSize)
        self.locale = locale
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
        searchPrefix = prefix
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

        if showsFavoritesOnly {
            refreshResults()
        } else {
            publishVisibleResults()
        }
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

    public var selectedMapViewModel: CityMapViewModel? {
        selectedCity.map(CityMapViewModel.init)
    }

    public func selectCity(withID cityID: Int?) {
        selectedCity = cityID.flatMap(visibleCity)
        publishVisibleResults()
    }

    public func detailViewModel(for cityID: Int) -> CityDetailViewModel? {
        visibleCity(withID: cityID).map {
            CityDetailViewModel(city: $0, isFavorite: favoriteIDs.contains($0.id), locale: locale)
        }
    }

    private func visibleCity(withID cityID: Int) -> City? {
        matchingResults?.limited(to: visibleCount).first { $0.id == cityID }
    }

    private func refreshResults() {
        guard let catalog else { return }
        let results = catalog.search(prefix: searchPrefix)
        matchingResults = showsFavoritesOnly ? results.filter(byFavoriteIDs: favoriteIDs) : results
        publishVisibleResults()
    }

    private func publishVisibleResults() {
        guard let matchingResults else { return }
        state = .loaded(
            CityCellViewModels(
                results: matchingResults.limited(to: visibleCount),
                favoriteIDs: favoriteIDs,
                selectedCityID: selectedCity?.id
            )
        )
    }
}
