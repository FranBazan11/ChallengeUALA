//
//  FavoritesStore.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

@MainActor
public protocol FavoritesStore {
    func loadFavoriteIDs() -> Set<Int>
    func setFavorite(_ cityID: Int, isFavorite: Bool)
}
