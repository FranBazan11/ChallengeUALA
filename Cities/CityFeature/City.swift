//
//  City.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

public struct City: Equatable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let countryCode: String
    public let latitude: Double
    public let longitude: Double

    public init(id: Int, name: String, countryCode: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
    }
}
