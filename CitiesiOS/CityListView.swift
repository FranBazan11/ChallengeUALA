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
    @State private var showsFavoritesOnly = false
    @State private var reloadToken = 0
    @FocusState private var isFilterFocused: Bool

    public init(viewModel: CityListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Filtrar por prefijo", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .focused($isFilterFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .padding(.horizontal)
                .padding(.top)
                .onChange(of: searchText) { _, newValue in
                    viewModel.search(prefix: newValue)
                }
                .onSubmit {
                    isFilterFocused = false
                }

            Toggle("Solo favoritos", isOn: $showsFavoritesOnly)
                .padding()
                .onChange(of: showsFavoritesOnly) { _, newValue in
                    viewModel.setFavoritesOnly(newValue)
                }

            content
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            isFilterFocused = false
        })
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
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(results) { city in
                    CityCellView(
                        viewModel: CityCellViewModel(city: city, isFavorite: viewModel.isFavorite(city.id)),
                        onToggleFavorite: { viewModel.toggleFavorite(cityID: city.id) }
                    )
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.immediately)
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
