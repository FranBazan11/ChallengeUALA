//
//  CityCellView.swift
//  CitiesiOS
//
//  Created by Juan Francisco Bazan Carrizo on 08/08/2026.
//

import SwiftUI
import Cities

struct CityCellView: View {
    let viewModel: CityCellViewModel
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .font(.headline)
                Text(viewModel.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onToggleFavorite) {
                Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(viewModel.isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isFavorite ? "Quitar de favoritos" : "Agregar a favoritos")
        }
    }
}
