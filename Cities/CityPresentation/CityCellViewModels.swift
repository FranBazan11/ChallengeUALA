//
//  CityCellViewModels.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 12/08/2026.
//

public struct CityCellViewModels: RandomAccessCollection, Sendable {
    private let results: CitySearchResults
    private let favoriteIDs: Set<Int>
    private let selectedCityID: Int?

    init(results: CitySearchResults, favoriteIDs: Set<Int>, selectedCityID: Int?) {
        self.results = results
        self.favoriteIDs = favoriteIDs
        self.selectedCityID = selectedCityID
    }

    public var startIndex: Int { results.startIndex }

    public var endIndex: Int { results.endIndex }

    public subscript(position: Int) -> CityCellViewModel {
        let city = results[position]
        return CityCellViewModel(
            city: city,
            isFavorite: favoriteIDs.contains(city.id),
            isSelected: city.id == selectedCityID
        )
    }
}
