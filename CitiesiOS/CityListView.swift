//
//  CityListView.swift
//  CitiesiOS
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import SwiftUI
import Cities

struct CityListView: View {
    let viewModel: CityListViewModel
    let onSelect: (Int) -> Void
    let onShowDetail: (Int) -> Void
    let onRetry: () -> Void

    @FocusState private var isFilterFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Filtrar por prefijo", text: Binding(
                get: { viewModel.searchPrefix },
                set: { viewModel.search(prefix: $0) }
            ))
            .textFieldStyle(.roundedBorder)
            .focused($isFilterFocused)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
            .padding(.horizontal)
            .padding(.top)
            .onSubmit {
                isFilterFocused = false
            }

            Toggle("Solo favoritos", isOn: Binding(
                get: { viewModel.showsFavoritesOnly },
                set: { viewModel.setFavoritesOnly($0) }
            ))
            .padding()

            content
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            isFilterFocused = false
        })
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            Spacer()
            ProgressView()
            Spacer()

        case let .loaded(cells):
            if cells.isEmpty {
                Spacer()
                Text("No encontramos ciudades para ese filtro")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(cells) { cell in
                    CityCellView(
                        viewModel: cell,
                        onToggleFavorite: { viewModel.toggleFavorite(cityID: cell.id) },
                        onShowDetail: { onShowDetail(cell.id) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(cell.id) }
                    .onAppear { viewModel.showMoreResults(after: cell.id) }
                    .listRowBackground(cell.isSelected ? Color.secondary.opacity(0.2) : nil)
                    .accessibilityAddTraits(cell.isSelected ? .isSelected : [])
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.immediately)
            }

        case let .failed(message):
            Spacer()
            VStack(spacing: 12) {
                Text(message)
                    .multilineTextAlignment(.center)
                Button("Reintentar", action: onRetry)
            }
            .padding()
            Spacer()
        }
    }
}
