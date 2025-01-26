//
//  ContentView.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 11/1/24.
//

import SwiftUI

struct ContentView: View {

    let geometries: [Geometry]
    let columns: [String]
    @Binding var selectedGeometries: Set<Geometry>

    var body: some View {
        TabView {
            MRMap(geometries: geometries, selection: $selectedGeometries)
                .tabItem {
                    Image(systemName: "map.circle")
                    Text("Map")

                }
                .tag(1)

            GeometriesTable(geometries: geometries,
                            columns: columns,
                            selection: $selectedGeometries)
                .tabItem {
                    Image(systemName: "list.bullet.circle")
                    Text("Geometries")
                }
                .tag(2)

            //            MRMap(geometries: viewModel.geometries, selection: $geometrySelection)
            //                .tabItem {
            //                    Image(systemName: "map.circle")
            //                    Text("Map")
            //                }
            //                .tag(1)
            //
            //            GeometriesTable(geometries: viewModel.geometries,
            //                            columns: viewModel.columns,
            //                            selection: $geometrySelection)
            //                .searchable(text: $viewModel.searchText)
            //                .tabItem {
            //                    Image(systemName: "list.bullet.circle")
            //                    Text("Geometries")
            //                }
            //                .tag(2)
        }
    }
}

//#Preview {
//    ContentView()
//}
