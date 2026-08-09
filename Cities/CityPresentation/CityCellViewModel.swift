//
//  CityCellViewModel.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

public struct CityCellViewModel: Equatable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String
    public let isFavorite: Bool

    public init(city: City, isFavorite: Bool) {
        id = city.id
        title = "\(city.name), \(city.countryCode)"
        subtitle = "\(city.latitude), \(city.longitude)"
        self.isFavorite = isFavorite
    }
}
