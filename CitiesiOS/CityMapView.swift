//
//  CityMapView.swift
//  CitiesiOS
//
//  Created by Juan Francisco Bazan Carrizo on 11/08/2026.
//

import SwiftUI
import MapKit
import Cities

struct CityMapView: View {
    let viewModel: CityMapViewModel?

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        if let viewModel {
            Map(position: $position) {
                Marker(viewModel.title, coordinate: coordinate(of: viewModel))
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel, initial: true) { _, selected in
                position = .region(region(of: selected))
            }
        } else {
            Text("Elegí una ciudad para verla en el mapa")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func coordinate(of viewModel: CityMapViewModel) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: viewModel.latitude, longitude: viewModel.longitude)
    }

    private func region(of viewModel: CityMapViewModel) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate(of: viewModel),
            latitudinalMeters: viewModel.spanInMeters,
            longitudinalMeters: viewModel.spanInMeters
        )
    }
}
