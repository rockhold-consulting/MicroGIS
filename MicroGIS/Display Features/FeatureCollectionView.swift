//
//  MainContent.swift
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
