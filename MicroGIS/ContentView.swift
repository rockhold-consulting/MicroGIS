//
//  ContentView.swift
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
import UniformTypeIdentifiers

enum SidebarItem: Hashable, Identifiable {
    var id: ObjectIdentifier {
        switch self {
        case .FeatureCollection(let fc):
            return fc.id
        case .Stylesheet(let ss):
            return ss.id
        }
    }

    case Stylesheet(Stylesheet)
    case FeatureCollection(FeatureCollection)
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var path = NavigationPath()

    @FetchRequest<Stylesheet>(sortDescriptors: [SortDescriptor(\.name)])
    private var stylesheets: FetchedResults<Stylesheet>

    @FetchRequest<FeatureCollection>(sortDescriptors: [SortDescriptor(\.creationDate)])
    private var featureCollections: FetchedResults<FeatureCollection>

    @State private var selectedSidebarItems = Set<SidebarItem>()

    @State private var importerIsPresented = false
    @State private var importingTask: Task<Void,any Error>? = nil

    var body: some View {
            NavigationSplitView {

                VStack {
                    List(selection: $selectedSidebarItems) {
                        Section {
                            ForEach(stylesheets.map({ s in
                                SidebarItem.Stylesheet(s)
                            }), id: \.self) { sbi in
                                if case .Stylesheet(let stylesheet) = sbi {
                                    NavigationLink(value: stylesheet) {
                                        Label(stylesheet.name ?? "-", systemImage: "paintpalette")
                                    }
                                } else {
                                    Text("stylesheet error")
                                }
                            }
                            .onDelete(perform: deleteStyleSheet)

                        } header: {
                            Text("Style Rules")
                        }

                        Section {
                            ForEach(featureCollections.map({ fc in
                                SidebarItem.FeatureCollection(fc)
                            }), id: \.self) { sbi in
                                if case .FeatureCollection(let featureCollection) = sbi {
                                    Label(featureCollection.name ?? "unnamed", systemImage:"rectangle.3.group")
                                } else {
                                    Text("featureCollection error")
                                }
                            }
                            .onDelete(perform: deleteItems)
                        } header: {
                            Text("Feature Collections")
                        }
                    }
                    .toolbar {
#if os(iOS)
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
#endif
                        ToolbarItem {
                            Button(action: addItem) {
                                Label("Import Features", systemImage: "plus")
                            }
                        }
                    }
                    .fileImporter(
                        isPresented: $importerIsPresented,
                        allowedContentTypes: [UTType(filenameExtension: "geojson", conformingTo: .json)!]
                    ) { result in
                        switch result {
                        case .success(let file):
                            importingTask = Task.detached {
                                PersistenceController.shared.importFeaturesFile(url: file)
                                try await Task.sleep(nanoseconds: UInt64(5 * Double(NSEC_PER_SEC)))
                                await MainActor.run {
                                    importingTask = nil
                                }
                            }
                        case .failure(let error):
                            // TODO: handle this error
                            print(error.localizedDescription)
                        }
                    }

                    if importingTask != nil {
                        Spacer()
                        Button("Cancel Importing") {
                            print("this is cancelling")
                            importingTask!.cancel()
                        }.padding()
                    }
                }
            } detail: {
                switch selectedSidebarItems.count {
                case 0:
                    Text("Select a feature collection or stylesheet in the sidebar.")
                case 1:
                    switch selectedSidebarItems.first! {
                    case .Stylesheet(let stylesheet):
                        Text("Stylesheet \(stylesheet.name ?? "--")")

                    case .FeatureCollection(let featureCollection):
                        FeatureCollectionView(context: viewContext,
                                              featureCollections: [featureCollection])
                        .id(collectionsHash([featureCollection]))
                    }
                default:
                    // if the sidebar-selection is all just FeatureCollection,
                    // display all the features of each together
                    let selectedFeatureCollections = allFeatureCollections(selectedSidebarItems)
                    switch selectedFeatureCollections.count {
                    case 0:
                        Text("Multiple items selected.")
                    default:
                        FeatureCollectionView(context: viewContext,
                                              featureCollections: selectedFeatureCollections)
                        .id(collectionsHash(selectedFeatureCollections))
                    }
                }
            }
    }

    private func collectionsHash(_ fcs: [FeatureCollection]) -> Int {
        var hasher = Hasher()
        hasher.combine(fcs)
        return hasher.finalize()
    }

    private func allFeatureCollections(_ items: Set<SidebarItem>) -> [FeatureCollection] {

        return items.compactMap { item in
            switch item {
            case .FeatureCollection(let featureCollection):
                return featureCollection
            default:
                return nil
            }
        }
    }

    private func addItem() {
        importerIsPresented = true
    }

    private func deleteStyleSheet(offsets: IndexSet) {
        withAnimation {
            offsets.map { stylesheets[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { featureCollections[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
