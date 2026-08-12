//
//  CompositionRoot.swift
//  ChallengeUALA
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import Foundation
import Cities
import CitiesiOS

enum CompositionRoot {
    nonisolated static let cityCatalogURL = URL(string: "https://gist.githubusercontent.com/hernan-uala/dce8843a8edbe0b0018b32e137bc2b3a/raw/0996accf70cb0ca0e16f9a99e0ee185fafca7af1/cities.json")!

    static func makeCityCatalogView() -> CityCatalogView {
        let viewModel = CityListViewModel(loader: makeCityCatalogLoader(), favoritesStore: makeFavoritesStore())
        return CityCatalogView(viewModel: viewModel)
    }

    nonisolated static func makeCityCatalogLoader(
        configuration: AppConfiguration = .current
    ) -> CityCatalogLoader {
        if let cityCatalogData = configuration.cityCatalogData {
            return LocalCityCatalogLoader(data: cityCatalogData)
        }
        return RemoteCityCatalogLoader(url: cityCatalogURL, client: URLSessionHTTPClient())
    }

    static func makeFavoritesStore() -> FavoritesStore {
        (try? SwiftDataFavoritesStore.makeDefault()) ?? InMemoryFavoritesStore()
    }
}
