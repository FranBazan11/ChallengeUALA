//
//  CityListView.swift
//  CitiesiOS
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import SwiftUI
import Cities

public struct CityListView: View {
    let viewModel: CityListViewModel

    @State private var searchText = ""
    @State private var reloadToken = 0

    public init(viewModel: CityListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Filtrar por prefijo", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onChange(of: searchText) { _, newValue in
                    viewModel.search(prefix: newValue)
                }

            content
        }
        .task(id: reloadToken) {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            Spacer()
            ProgressView()
            Spacer()

        case let .loaded(results):
            if results.isEmpty {
                Spacer()
                Text("No encontramos ciudades para ese filtro")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(results) { city in
                    CityCellView(viewModel: CityCellViewModel(city: city))
                }
                .listStyle(.plain)
            }

        case let .failed(message):
            Spacer()
            VStack(spacing: 12) {
                Text(message)
                    .multilineTextAlignment(.center)
                Button("Reintentar") {
                    reloadToken += 1
                }
            }
            .padding()
            Spacer()
        }
    }
}
