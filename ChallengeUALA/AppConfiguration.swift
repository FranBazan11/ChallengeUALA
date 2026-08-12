//
//  AppConfiguration.swift
//  ChallengeUALA
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import Foundation

nonisolated struct AppConfiguration {
    static let cityCatalogJSONKey = "CITY_CATALOG_JSON"

    static var current: AppConfiguration {
        AppConfiguration(environment: ProcessInfo.processInfo.environment)
    }

    let cityCatalogData: Data?

    init(cityCatalogData: Data? = nil) {
        self.cityCatalogData = cityCatalogData
    }

    init(environment: [String: String]) {
        let json = environment[Self.cityCatalogJSONKey]
        self.init(cityCatalogData: json.flatMap { $0.isEmpty ? nil : Data($0.utf8) })
    }
}
