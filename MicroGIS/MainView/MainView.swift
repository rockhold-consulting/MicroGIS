//
//  MainView.swift
//  MicroGIS
//
// Copyright 2023, 2024, Michael Rockhold (dba Rockhold Software)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// The license is provided with this work, or you may obtain a copy
// of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Michael Rockhold on 7/4/24.
//

import SwiftUI
import CoreData

extension FeatureCollection {
    // TODO: temporary, will be replaced by using a query later
    func allGeometries() -> [Geometry] {
        var acc = [Geometry]()
        for f in (self.features?.allObjects as? [Feature]) ?? [] {
            if let geometries = f.geometries?.allObjects as? [Geometry] {
                acc.append(contentsOf: geometries)
            }
        }
        return acc
    }
}

struct MainView: View {
    
    @State private var path = NavigationPath()
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest<FeatureCollection>(sortDescriptors: [SortDescriptor(\.creationDate)])
    public var featureCollections: FetchedResults<FeatureCollection>

    @StateObject private var viewModel: CollectionMenuViewModel = CollectionMenuViewModel()
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            CollectionMenuView(viewModel: viewModel, featureCollections: featureCollections)
        } content: {
            MacContentView(viewModel: viewModel)
            .searchable(text: $viewModel.searchText)
            
        } detail: {
            DetailView(selection: $viewModel.geometrySelection,
                       geometryColumns: $viewModel.geometryColumns)
                .padding(20)
            Spacer()
        }
        .onAppear {
            self.viewModel.appearing(viewContext: viewContext)
        }
        .onChange(of: viewModel.selectedFeatureCollection) { sfc in
            self.viewModel.changing(selection: sfc)
        }
        .onChange(of: viewModel.searchText) { txt in
            self.viewModel.changing(searchText: txt)
        }
        #endif
        #if os(iOS)
        NavigationSplitView {
            CollectionMenuView(viewModel: viewModel,
                               featureCollections: featureCollections)
        } detail: {
            iOSContentView(viewModel: viewModel)
                .searchable(text: $viewModel.searchText)
        }
        .onAppear {
            self.viewModel.appearing(viewContext: viewContext)
        }
        .onChange(of: viewModel.selectedFeatureCollection) { sfc in
            self.viewModel.changing(selection: sfc)
        }
        #endif

    }
}
