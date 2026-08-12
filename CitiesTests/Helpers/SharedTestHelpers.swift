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

let largeCityListSize = 200_000

func makeLargeCityList(count: Int = largeCityListSize) -> [City] {
    let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

    return (0..<count).map { index in
        let name = String([
            alphabet[index % 26],
            alphabet[(index / 26) % 26],
            alphabet[(index / 676) % 26],
            alphabet[(index / 17_576) % 26]
        ])

        return City(
            id: index,
            name: name + String(index),
            countryCode: "US",
            latitude: 0,
            longitude: 0
        )
    }
}

actor CityCatalogLoaderStub: CityCatalogLoader {
    private var results: [Result<CityCatalog, CityCatalogLoadError>]

    init(results: [Result<CityCatalog, CityCatalogLoadError>]) {
        self.results = results
    }

    func load() async throws(CityCatalogLoadError) -> CityCatalog {
        switch results.removeFirst() {
        case let .success(catalog):
            return catalog
        case let .failure(error):
            throw error
        }
    }
}
