//
//  GeometriesInfo.swift
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
//  Created by Michael Rockhold on 8/26/24.
//

import SwiftUI

struct GeometriesInfo: View {
    let geometries: Set<Geometry>

    var body: some View {
        switch geometries.count {
        case 0:
            Text("Select geometries in the table or the map.")
                .padding(20)

            Spacer()

        case 1:
#if os(macOS)
            ScrollView {
                GeometryInfo(geometry: geometries.first!)
            }
            .padding(20)
#else
            GeometryInfo(geometry: geometries.first!)
#endif

        default:
            Text("multiple (\(geometries.count)) geometries selected")
                .padding(20)
            Spacer()
        }
    }
}
