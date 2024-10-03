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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var selection = Set<Geometry>()

    @StateObject private var viewModel: FeatureCollectionModel

    init(context: NSManagedObjectContext, featureCollections: [FeatureCollection]) {
        self._viewModel = StateObject(wrappedValue: FeatureCollectionModel(context: context, featureCollections: featureCollections))
    }

    var body: some View {

        switch horizontalSizeClass {
        case .compact:
            TabView {
                MRMap(geometries: viewModel.geometries, selection: $selection)
                    .tabItem {
                        Image(systemName: "map.circle")
                        Text("Map")
                    }
                    .tag(1)

                GeometriesTable(geometries: viewModel.geometries,
                                columns: viewModel.columns,
                                selection: $selection)
                    .searchable(text: $viewModel.searchText)
                    .tabItem {
                        Image(systemName: "list.bullet.circle")
                        Text("Geometries")
                    }
                    .tag(3)

                switch selection.count {
                case 0:
                    Text("Select geometries in the table or the map.")
                        .padding(20)
                        .tabItem {
                            Image(systemName: "0.circle")
                            Text("No Selection")
                        }
                        .tag(0)
                case 1:
                    GeometryInfo(geometry: selection.first!)
                        .tabItem {
                            Image(systemName: "square.and.pencil")
                            Text("Details")
                        }
                        .tag(2)
                default:
                    Text("Multiple selection: yet to be implemented")
                        .padding(20)
                        .tabItem {
                            Image(systemName: "square.and.pencil")
                            Text("Details")
                        }
                        .tag(99)
                }
            }
        case .regular:
            HStack {
                VStack {
                    MRMap(geometries: viewModel.geometries, selection: $selection)

                    GeometriesInfo(geometries: selection)
                }
                GeometriesTable(geometries: viewModel.geometries,
                                columns: viewModel.columns,
                                selection: $selection)
                .frame(width: 240)
            }
            .searchable(text: $viewModel.searchText)
        case .none:
            Text("NONE")
        case .some(let _):
            Text("SOME")
        }


    }
}
