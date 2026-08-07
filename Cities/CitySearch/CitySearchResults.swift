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
}
