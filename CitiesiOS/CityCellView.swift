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

    var body: some View {
        VStack(alignment: .leading) {
            Text(viewModel.title)
                .font(.headline)
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
