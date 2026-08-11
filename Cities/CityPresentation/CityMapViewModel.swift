//
//  CityMapViewModel.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

public struct CityMapViewModel: Hashable, Identifiable, Sendable {
    public static let defaultSpanInMeters: Double = 20_000

    public let id: Int
    public let title: String
    public let latitude: Double
    public let longitude: Double
    public let spanInMeters: Double

    public init(city: City) {
        id = city.id
        title = "\(city.name), \(city.countryCode)"
        latitude = city.latitude
        longitude = city.longitude
        spanInMeters = Self.defaultSpanInMeters
    }
}
