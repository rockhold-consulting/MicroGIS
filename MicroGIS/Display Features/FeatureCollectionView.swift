//
//  MainContent.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 5/22/24.
//

import SwiftUI
import CoreData


struct FeatureCollectionView: View {

    @State private var selection = Set<Geometry>()
    @State var searchText = ""

    let viewModel: FeatureCollectionViewModel

    var body: some View {

        VStack {
            MRMap(geometries: viewModel.geometries, selection: $selection)
            HStack {
                GeometriesTable(geometries: viewModel.geometries,
                                columns: viewModel.columns,
                                    selection: $selection,
                                    searchText: $searchText)

                GeometriesInfo(geometries: selection)
            }
        }
        .searchable(text: $searchText)

    }
}
