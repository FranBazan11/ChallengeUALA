//
//  CityDetailViewModel.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 12/08/2026.
//

import Foundation

public struct CityDetailViewModel: Equatable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let countryName: String
    public let latitudeText: String
    public let longitudeText: String
    public let identifierText: String
    public let isFavorite: Bool
    public let map: CityMapViewModel

    public init(city: City, isFavorite: Bool, locale: Locale = .current) {
        id = city.id
        title = "\(city.name), \(city.countryCode)"
        countryName = locale.localizedString(forRegionCode: city.countryCode) ?? city.countryCode
        latitudeText = Self.sexagesimalText(for: city.latitude, positiveHemisphere: "N", negativeHemisphere: "S")
        longitudeText = Self.sexagesimalText(for: city.longitude, positiveHemisphere: "E", negativeHemisphere: "O")
        identifierText = String(city.id)
        self.isFavorite = isFavorite
        map = CityMapViewModel(city: city)
    }

    private static func sexagesimalText(
        for coordinate: Double,
        positiveHemisphere: String,
        negativeHemisphere: String
    ) -> String {
        let hemisphere = coordinate < 0 ? negativeHemisphere : positiveHemisphere
        let totalSeconds = Int((abs(coordinate) * 3600).rounded())
        let degrees = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return "\(degrees)°\(zeroPadded(minutes))'\(zeroPadded(seconds))\" \(hemisphere)"
    }

    private static func zeroPadded(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}
