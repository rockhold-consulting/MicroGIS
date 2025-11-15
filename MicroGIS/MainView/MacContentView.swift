//
//  MacContentView.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 11/1/24.
//

import SwiftUI

struct MacContentView: View {

    @ObservedObject var viewModel: CollectionMenuViewModel
    @Environment(\.dismissSearch) private var dismissSearch

    var body: some View {
        VStack {
            MRMap(geometries: viewModel.geometries, selection: $viewModel.geometrySelection)

            GeometriesTable(geometries: viewModel.geometries,
                            columns: viewModel.geometryColumns,
                            selection: $viewModel.geometrySelection)
        }
        .onChange(of: viewModel.searchText) { txt in
            self.viewModel.changing(searchText: txt)
        }
    }
}

//#Preview {
//    ContentView()
//}
