//
//  CityCatalogMapper.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

import Foundation

public enum CityCatalogMapper {

    public enum Error: Swift.Error {
        case invalidData
    }

    public static func map(_ data: Data) throws -> CityCatalog {
        guard let remoteCities = try? JSONDecoder().decode([RemoteCity].self, from: data) else {
            throw Error.invalidData
        }

        return CityCatalog(cities: remoteCities.map(\.city))
    }

    private struct RemoteCity: Decodable {
        let identifier: Int
        let name: String
        let country: String
        let coordinate: RemoteCoordinate

        var city: City {
            City(
                id: identifier,
                name: name,
                countryCode: country,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }

        enum CodingKeys: String, CodingKey {
            case identifier = "_id"
            case name
            case country
            case coordinate = "coord"
        }

        struct RemoteCoordinate: Decodable {
            let latitude: Double
            let longitude: Double

            enum CodingKeys: String, CodingKey {
                case latitude = "lat"
                case longitude = "lon"
            }
        }
    }
}
