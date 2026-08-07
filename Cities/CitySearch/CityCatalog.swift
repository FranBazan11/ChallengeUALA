//
//  CityCatalog.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

public struct CityCatalog: Sendable {
    public let cities: [City]

    private let searchIndex: [CitySearchEntry]

    public init(cities: [City]) {
        self.cities = cities
        self.searchIndex = Self.buildIndex(cities)
    }

    public func search(prefix: String) -> CitySearchResults {
        guard !prefix.isEmpty else {
            return CitySearchResults(cities: cities, entries: searchIndex[...])
        }

        let key = prefix.lowercased()
        let endOfPrefixRange = key + Self.highestUnicodeScalar
        let start = searchIndex.lowerBound { $0.searchKey < key }
        let end = searchIndex.lowerBound { $0.searchKey < endOfPrefixRange }

        return CitySearchResults(cities: cities, entries: searchIndex[start..<end])
    }

    private static let highestUnicodeScalar = "\u{10FFFF}"

    private static func buildIndex(_ cities: [City]) -> [CitySearchEntry] {
        cities.enumerated()
            .map { index, city in
                CitySearchEntry(
                    searchKey: "\(city.name), \(city.countryCode)".lowercased(),
                    cityIndex: index
                )
            }
            .sorted { $0.searchKey < $1.searchKey }
    }
}
