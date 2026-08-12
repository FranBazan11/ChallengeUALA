//
//  UITestCityCatalog.swift
//  ChallengeUALAUITests
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import Foundation

enum UITestCityCatalog {
    static let citiesPerPage = 50

    static var json: String {
        let entries = citiesSpanningMoreThanOnePage + [cityFromTheChallengeExample]
        let data = try! JSONSerialization.data(withJSONObject: entries)
        return String(decoding: data, as: UTF8.self)
    }

    static var firstCityName: String { zeroPaddedName(1) }

    static var secondCityName: String { zeroPaddedName(2) }

    static var cityBeyondTheFirstPageName: String { zeroPaddedName(citiesPerPage + 10) }

    static let cityOutsideTheSharedPrefixName = "Hurzuf"

    static let sharedPrefix = "Ciudad"

    private static var citiesSpanningMoreThanOnePage: [[String: Any]] {
        (1...citiesPerPage + 10).map { position in
            entry(
                id: position,
                name: zeroPaddedName(position),
                country: "AR",
                latitude: Double(position),
                longitude: Double(position)
            )
        }
    }

    private static var cityFromTheChallengeExample: [String: Any] {
        entry(
            id: 707860,
            name: cityOutsideTheSharedPrefixName,
            country: "UA",
            latitude: 44.549999,
            longitude: 34.283333
        )
    }

    private static func entry(
        id: Int,
        name: String,
        country: String,
        latitude: Double,
        longitude: Double
    ) -> [String: Any] {
        [
            "_id": id,
            "name": name,
            "country": country,
            "coord": ["lat": latitude, "lon": longitude]
        ]
    }

    private static func zeroPaddedName(_ position: Int) -> String {
        String(format: "\(sharedPrefix) %02d", position)
    }
}
