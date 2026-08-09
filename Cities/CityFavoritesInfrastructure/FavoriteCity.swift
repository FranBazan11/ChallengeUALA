//
//  FavoriteCity.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 09/08/2026.
//

import SwiftData

@Model
final class FavoriteCity {
    var cityID: Int

    init(cityID: Int) {
        self.cityID = cityID
    }
}
