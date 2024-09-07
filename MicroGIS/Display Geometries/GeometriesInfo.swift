//
//  GeometriesInfo.swift
//  MicroGIS
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
