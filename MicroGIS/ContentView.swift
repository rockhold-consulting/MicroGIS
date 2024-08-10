//
//  ContentView.swift
//  MicroGIS
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

    @State private var geometriesFetchRequest = NSFetchRequest<Geometry>(entityName: "Geometry")

    @State private var selectedSidebarItem: SidebarItem?
    @State private var selectedGeometries = Set<Geometry>()

    @State private var importing = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSidebarItem) {
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
                isPresented: $importing,
                allowedContentTypes: [UTType(filenameExtension: "geojson", conformingTo: .json)!]
            ) { result in
                switch result {
                case .success(let file):
                    // TODO: perform this in the background, while displaying the progress of the import in the status view.
                    PersistenceController.shared.importFeaturesFile(url: file)
                case .failure(let error):
                    // TODO: handle this error
                    print(error.localizedDescription)
                }
            }
        } detail: {
            switch selectedSidebarItem {
            case .Stylesheet(let stylesheet):
                Text("Stylesheet \(stylesheet.name ?? "--")")

            case .FeatureCollection(let featureCollection):
                let vm = createFeatureCollectionViewModel([featureCollection])
                FeatureCollectionView(geometries: vm.geometries,
                                      columns: vm.columns,
                                      selection: $selectedGeometries)
                .onChange(of: selectedSidebarItem) { model in
                    selectedGeometries.removeAll()
                }
                
            case nil:
                Text("Select a feature collection or stylesheet in the sidebar.")
            }
        }
    }

    private func createFeatureCollectionViewModel(_ featureCollections: [FeatureCollection]) -> FeatureCollectionViewModel {
        let frA = NSPredicate(format: "feature.collection IN %@",
                                                       argumentArray: [featureCollections])

        let frB = NSPredicate(format: "rawShapeCode = %d", Geometry.GeoShapeType.Polygon.rawValue)
        geometriesFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [frA])
        return FeatureCollectionViewModel(context: viewContext, fetchRequest: geometriesFetchRequest)
    }

    private func addItem() {
        importing = true
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

//#Preview {
//    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
