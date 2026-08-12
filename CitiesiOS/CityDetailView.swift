//
//  CityDetailView.swift
//  CitiesiOS
//
//  Created by Juan Francisco Bazan Carrizo on 12/08/2026.
//

import SwiftUI
import Cities

struct CityDetailView: View {
    let viewModel: CityDetailViewModel
    let onToggleFavorite: () -> Void
    let onClose: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        NavigationStack {
            List {
                Section {
                    CityMapView(viewModel: viewModel.map)
                        .frame(height: mapHeight)
                        .listRowInsets(EdgeInsets())
                }

                Section("Ubicación") {
                    DetailRow(label: "País", value: viewModel.countryName)
                    DetailRow(label: "Latitud", value: viewModel.latitudeText)
                    DetailRow(label: "Longitud", value: viewModel.longitudeText)
                }

                Section("Identificación") {
                    DetailRow(label: "Identificador", value: viewModel.identifierText)
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar", action: onClose)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onToggleFavorite) {
                        Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(viewModel.isFavorite ? .yellow : .secondary)
                    }
                    .accessibilityLabel(viewModel.isFavorite ? "Quitar de favoritos" : "Agregar a favoritos")
                }
            }
        }
    }

    private var mapHeight: CGFloat {
        verticalSizeClass == .compact ? 110 : 180
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .accessibilityElement(children: .combine)
    }
}
