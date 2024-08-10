//
//  GeometryLocationView.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/28/24.
//

import SwiftUI

struct GeometryLocationView: View {

    private let geometry: Geometry
    @State private var centerLatitude: Double
    @State private var centerLongitude: Double
    private let saver: ()->Void

    init(geometry: Geometry, saver: @escaping ()->Void) {
        self.geometry = geometry
        self.saver = saver
        self.centerLatitude = geometry.centerLatitude
        self.centerLongitude = geometry.centerLongitude
    }

    var body: some View {
        TextField(value: $centerLatitude,
                  format: .number.precision(Decimal.FormatStyle.Configuration.Precision.fractionLength(0..<9))) { Text("Latitude") }
                  .disabled(!geometry.centerIsMovable)
                  .textSelection(.enabled)
                  .disableAutocorrection(true)
                  .onChange(of: centerLatitude) { v in
                      geometry.centerLatitude = v
                      saver()
                  }

        TextField(value: $centerLongitude,
                  format: .number.precision(Decimal.FormatStyle.Configuration.Precision.fractionLength(0..<9))) { Text("Longitude") }
                  .disabled(!geometry.centerIsMovable)
                  .textSelection(.enabled)
                  .disableAutocorrection(true)
                  .onChange(of: centerLongitude) { v in
                      geometry.centerLongitude = v
                      saver()
                  }
    }
}
