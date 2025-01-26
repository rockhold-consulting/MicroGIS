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
    
    func delete(context: NSManagedObjectContext) {
        switch self {
        case .FeatureCollection(let fc):
            context.delete(fc)
        case .Stylesheet(let ss):
            context.delete(ss)
        }
    }
    
    case Stylesheet(Stylesheet)
    case FeatureCollection(FeatureCollection)
}

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
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var path = NavigationPath()
    
    //    @FetchRequest<Stylesheet>(sortDescriptors: [SortDescriptor(\.name)])
    //    private var stylesheets: FetchedResults<Stylesheet>
    
    @FetchRequest<FeatureCollection>(sortDescriptors: [SortDescriptor(\.creationDate)])
    private var featureCollections: FetchedResults<FeatureCollection>
    
    //    @State private var selectedSidebarItems = Set<SidebarItem>()
    @State private var selectedFeatureCollection: FeatureCollection? = nil
    
    @State private var geometries = [Geometry]()
    @State private var geometryColumns = [String]()
    @State private var geometrySelection = Set<Geometry>()
    @State private var searchText = ""
    @Environment(\.dismissSearch) private var dismissSearch
    @State private var importerIsPresented = false
    @State private var importingTask: Task<Void,any Error>? = nil
    
    private func fetchGeometries(request: NSFetchRequest<Geometry>) -> [Geometry] {
       do {
           let rv = try viewContext.fetch(request)
           return rv
       } catch {
           fatalError()
       }
   }

    var body: some View {
        NavigationSplitView {
            
            VStack {
                List(featureCollections, id: \.self, selection: $selectedFeatureCollection) { featureCollection in
                    //                    Section {
                    //                        ForEach(stylesheets.map({ s in
                    //                            SidebarItem.Stylesheet(s)
                    //                        }), id: \.self) { sbi in
                    //                            if case .Stylesheet(let stylesheet) = sbi {
                    //                                NavigationLink(value: stylesheet) {
                    //                                    Label(stylesheet.name ?? "-", systemImage: "paintpalette")
                    //                                }
                    //                            } else {
                    //                                Text("stylesheet error")
                    //                            }
                    //                        }
                    //                        .onDelete(perform: deleteStyleSheet)
                    //
                    //                    } header: {
                    //                        Text("Style Rules")
                    //                    }
                    
                    
                    Label(featureCollection.name ?? "unnamed", systemImage:"rectangle.3.group")
                }
                #if os(macOS)
                .onDeleteCommand(perform: {
                    deleteSelectedFeatureCollection()
                })
                #endif
                .navigationTitle(Text("Feature Collections"))
                
#if os(macOS)
                .keyboardShortcut(.delete, modifiers: [])
                .onDeleteCommand(perform: delete)
                .toolbar {
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Import Features", systemImage: "plus")
                        }
                    }
                }
#endif
#if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: addItem) {
                            Label("Import Features", systemImage: "plus")
                        }
                    }
                }
#endif
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
                        importingTask = nil
                    }.padding()
                }
            }
        } content: {
            ContentView(geometries: geometries,
                        columns: geometryColumns,
                        selectedGeometries: $geometrySelection)
            .searchable(text: $searchText)
        } detail: {
            DetailView(geometries: $geometrySelection)
                .padding(20)
        }
        .onAppear {
            if let fc = selectedFeatureCollection {
                self.refresh(featureCollection: fc)
            }
        }
        .onChange(of: selectedFeatureCollection) { sfc in
            if let fc = sfc {
                self.refresh(featureCollection: fc, searchText: "")
            } else {
                self.geometries.removeAll()
            }
        }
        .onChange(of: searchText) { txt in
            if let fc = selectedFeatureCollection {
                self.refresh(featureCollection: fc, searchText: txt)
            }
        }
    }

    private func refresh(featureCollection: FeatureCollection, searchText: String = "") {

        geometrySelection.removeAll()

        let fetchRequest = NSFetchRequest<Geometry>(entityName: "Geometry")

        var predicates = [NSPredicate]()
        let featureCollectionArray = [featureCollection]
        let p = NSPredicate(format: "feature.collection IN %@", argumentArray: [featureCollectionArray])
        predicates.append(p)

        // TODO: flesh out this rudimentary query language
        switch searchText.uppercased().trimmingCharacters(in: .whitespaces) {
        case "LINE":
            predicates.append(NSPredicate(format: "rawShapeCode = %d", Geometry.GeoShapeType.Polyline.rawValue))
        case "POINT":
            predicates.append(NSPredicate(format: "rawShapeCode = %d", Geometry.GeoShapeType.Point.rawValue))
        case "POLYGON":
            predicates.append(NSPredicate(format: "rawShapeCode = %d", Geometry.GeoShapeType.Polygon.rawValue))
        default: // not a valid query, add no other predicates; in effect, "select *"
            break
        }

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let gg: [Geometry]
        do {
            gg = try viewContext.fetch(fetchRequest)
            self.geometries.replaceSubrange(0..., with: gg)
        } catch {
            fatalError()
        }

        let features = gg.compactMap { g in
            g.feature
        }
        let columns = features.reduce(Set<String>()) { set, f in
            return set.union(f.propertyKeys())
        }
            .sorted(using: .localizedStandard)
        if columns.isEmpty {
            self.geometryColumns.removeAll()
        } else {
            self.geometryColumns.replaceSubrange(0..., with: columns)
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
    
    private func delete() {
        //        selectedSidebarItems.forEach { item in
        //            item.delete(context: viewContext)
        //        }
        //        saveContext()
    }
    
    private func deleteStyleSheet(offsets: IndexSet) {
        //        withAnimation {
        //            offsets.map { stylesheets[$0] }.forEach(viewContext.delete)
        //            saveContext()
        //        }
    }
    
    private func deleteSelectedFeatureCollection() {
        guard let sfc = selectedFeatureCollection else { return }
        withAnimation {
            viewContext.delete(sfc)

            geometries = [Geometry]()
            geometryColumns = [String]()
            geometrySelection = Set<Geometry>()
            searchText = ""
            selectedFeatureCollection = nil

            saveContext()
        }
    }
    
    private func saveContext() {
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
