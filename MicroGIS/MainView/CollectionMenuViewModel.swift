//
//  CollectionMenuViewModel.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 2025-02-03.
//

import SwiftUI
import CoreData

@MainActor
class CollectionMenuViewModel: ObservableObject {

    var viewContext: NSManagedObjectContext! = nil

    @Published var selectedFeatureCollection: FeatureCollection? = nil
    @Published var geometries = [GeometryItem]()
    @Published var geometrySelection = Set<GeometryItem.ID>()
    @Published var geometryColumns = [String]()
    @Published var searchText = ""
        
    public func appearing(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        
        if let fc = selectedFeatureCollection {
            refresh(featureCollection: fc)
        }
    }
    
    public func changing(selection sfc: FeatureCollection?) {
        if let fc = sfc {
            self.refresh(featureCollection: fc, searchText: "")
        } else {
            self.resetGeometries()
        }
    }
    
    public func changing(searchText txt: String) {
        if let fc = selectedFeatureCollection {
            self.refresh(featureCollection: fc, searchText: txt)
        }
    }
    
    public func refresh(featureCollection: FeatureCollection, searchText: String = "") {
        
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

        let gg: [GeometryItem]
        do {
            gg = try viewContext.fetch(fetchRequest).map { GeometryItem(geometry: $0) }
            self.geometries.replaceSubrange(0..., with: gg)
        } catch {
            fatalError()
        }

        let features = gg.compactMap { g in
            g.geometry.feature
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

    public func resetGeometries() {
        geometries.removeAll()
    }
    
    public func deleteSelectedFeatureCollection() {
        guard let sfc = selectedFeatureCollection else { return }
        viewContext.delete(sfc)
        reset()
    }
    
    public func reset() {
        geometries = [GeometryItem]()
        geometryColumns = [String]()
        geometrySelection = Set<GeometryItem.ID>()
        searchText = ""
        selectedFeatureCollection = nil
        saveContext()
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
