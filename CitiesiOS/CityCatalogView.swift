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

    @State private var detailCity: CityDetailViewModel?
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
            .sheet(item: $detailCity) { detail in
                CityDetailView(
                    viewModel: detail,
                    onToggleFavorite: {
                        viewModel.toggleFavorite(cityID: detail.id)
                        detailCity = viewModel.detailViewModel(for: detail.id)
                    },
                    onClose: { detailCity = nil }
                )
            }
    }

    @ViewBuilder
    private var layout: some View {
        if verticalSizeClass == .compact {
            HStack(spacing: 0) {
                list
                Divider()
                CityMapView(viewModel: viewModel.selectedMapViewModel)
            }
        } else {
            NavigationStack {
                list
                    .navigationDestination(item: selectedCity) { selected in
                        CityMapView(viewModel: selected)
                            .navigationTitle(selected.title)
                            .navigationBarTitleDisplayMode(.inline)
                    }
            }
        }
    }

    private var selectedCity: Binding<CityMapViewModel?> {
        Binding(
            get: { viewModel.selectedMapViewModel },
            set: { viewModel.selectCity(withID: $0?.id) }
        )
    }

    private var list: some View {
        CityListView(
            viewModel: viewModel,
            onSelect: { viewModel.selectCity(withID: $0) },
            onShowDetail: { detailCity = viewModel.detailViewModel(for: $0) },
            onRetry: { reloadToken += 1 }
        )
    }
}
