//
//  CityCatalogView.swift
//  CitiesiOS
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import SwiftUI
import Cities

public struct CityCatalogView: View {
    let viewModel: CityListViewModel

    @State private var selectedCity: CityMapViewModel?
    @State private var reloadToken = 0
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init(viewModel: CityListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        layout
            .task(id: reloadToken) {
                await viewModel.load()
            }
    }

    @ViewBuilder
    private var layout: some View {
        if verticalSizeClass == .compact {
            HStack(spacing: 0) {
                list
                Divider()
                CityMapView(viewModel: selectedCity)
            }
        } else {
            NavigationStack {
                list
                    .navigationDestination(item: $selectedCity) { selected in
                        CityMapView(viewModel: selected)
                    }
            }
        }
    }

    private var list: some View {
        CityListView(
            viewModel: viewModel,
            onSelect: { selectedCity = viewModel.mapViewModel(for: $0) },
            onRetry: { reloadToken += 1 }
        )
    }
}
