//
//  SharedTestHelpers.swift
//  CitiesTests
//
//  Created by Juan Francisco Bazan Carrizo on 07/08/2026.
//

import Foundation
import Cities

func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

func anyData() -> Data {
    Data("any data".utf8)
}

func makeCity(
    id: Int,
    name: String,
    countryCode: String,
    latitude: Double,
    longitude: Double
) -> (model: City, json: [String: Any]) {
    let model = City(id: id, name: name, countryCode: countryCode, latitude: latitude, longitude: longitude)

    let json: [String: Any] = [
        "_id": id,
        "name": name,
        "country": countryCode,
        "coord": ["lat": latitude, "lon": longitude]
    ]

    return (model, json)
}

func makeCatalogJSON(_ cities: [[String: Any]]) -> Data {
    try! JSONSerialization.data(withJSONObject: cities)
}
