//
//  SwiftDataFavoritesStore.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

import Foundation
import SwiftData

@MainActor
public final class SwiftDataFavoritesStore: FavoritesStore {
    private let context: ModelContext

    private init(container: ModelContainer) {
        context = ModelContext(container)
    }

    public convenience init(storeURL: URL) throws {
        let configuration = ModelConfiguration(url: storeURL)
        self.init(container: try ModelContainer(for: FavoriteCity.self, configurations: configuration))
    }

    public static func makeDefault() throws -> SwiftDataFavoritesStore {
        SwiftDataFavoritesStore(container: try ModelContainer(for: FavoriteCity.self))
    }

    public func loadFavoriteIDs() -> Set<Int> {
        let favorites = (try? context.fetch(FetchDescriptor<FavoriteCity>())) ?? []
        return Set(favorites.map(\.cityID))
    }

    public func setFavorite(_ cityID: Int, isFavorite: Bool) {
        switch (isFavorite, storedFavorite(for: cityID)) {
        case (true, .none):
            context.insert(FavoriteCity(cityID: cityID))
        case let (false, .some(favorite)):
            context.delete(favorite)
        default:
            return
        }
        try? context.save()
    }

    private func storedFavorite(for cityID: Int) -> FavoriteCity? {
        let descriptor = FetchDescriptor<FavoriteCity>(predicate: #Predicate { $0.cityID == cityID })
        return try? context.fetch(descriptor).first
    }
}
