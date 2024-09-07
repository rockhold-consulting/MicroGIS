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

    @StateObject private var viewModel: FeatureCollectionModel

    init(context: NSManagedObjectContext, featureCollections: [FeatureCollection]) {
        self._viewModel = StateObject(wrappedValue: FeatureCollectionModel(context: context, featureCollections: featureCollections))
    }

    var body: some View {

        VStack {
            MRMap(geometries: viewModel.geometries, selection: $selection)
            HStack {
                GeometriesTable(geometries: viewModel.geometries,
                                columns: viewModel.columns,
                                    selection: $selection)

                GeometriesInfo(geometries: selection)
            }
        }
        .searchable(text: $viewModel.searchText)

    }
}
