//
//  InMemoryFavoritesStore.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

@MainActor
public final class InMemoryFavoritesStore: FavoritesStore {
    private var favoriteIDs: Set<Int> = []

    public init() {}

    public func loadFavoriteIDs() -> Set<Int> {
        favoriteIDs
    }

    public func setFavorite(_ cityID: Int, isFavorite: Bool) {
        if isFavorite {
            favoriteIDs.insert(cityID)
        } else {
            favoriteIDs.remove(cityID)
        }
    }
}
