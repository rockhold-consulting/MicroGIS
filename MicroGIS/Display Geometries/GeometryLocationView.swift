//
//  GeometryLocationView.swift
//  MicroGIS
//
//  Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  The license is provided with this work, or you may obtain a copy
//  of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
