//
//  CitySearchResults.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

public struct CitySearchResults: RandomAccessCollection, Sendable {
    private let cities: [City]
    private let entries: ArraySlice<CitySearchEntry>

    init(cities: [City], entries: ArraySlice<CitySearchEntry>) {
        self.cities = cities
        self.entries = entries
    }

    public var startIndex: Int { entries.startIndex }

    public var endIndex: Int { entries.endIndex }

    public subscript(position: Int) -> City {
        cities[entries[position].cityIndex]
    }

    public func limited(to maxCount: Int) -> CitySearchResults {
        CitySearchResults(cities: cities, entries: entries.prefix(maxCount))
    }

    public func filter(byFavoriteIDs favoriteIDs: Set<Int>) -> CitySearchResults {
        let favoriteEntries = entries.filter { favoriteIDs.contains(cities[$0.cityIndex].id) }
        return CitySearchResults(cities: cities, entries: favoriteEntries[...])
    }
}
