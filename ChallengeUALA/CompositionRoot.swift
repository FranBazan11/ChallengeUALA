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

    static func makeCityListView() -> CityListView {
        let client = URLSessionHTTPClient()
        let loader = RemoteCityCatalogLoader(url: cityCatalogURL, client: client)
        let favoritesStore: FavoritesStore = (try? SwiftDataFavoritesStore.makeDefault()) ?? InMemoryFavoritesStore()
        let viewModel = CityListViewModel(loader: loader, favoritesStore: favoritesStore)
        return CityListView(viewModel: viewModel)
    }
}
