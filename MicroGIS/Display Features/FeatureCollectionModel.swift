//
//  FeatureCollectionModel.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 7/15/24.
//

import Foundation
import CoreData
import SwiftUI

extension Feature {
    public func matches(searchText: String) -> Bool {
        // TODO: search feature properties too
        if self.objectID.shortName.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        return false
    }
}

extension Geometry {
    public func matches(searchText: String) -> Bool {
        return false
    }
}

class FeatureCollectionModel: Hashable, ObservableObject {

    private var context: NSManagedObjectContext
    private var baseGeometriesPredicate: NSPredicate
    var searchText = "" {
        didSet {
            refresh()
        }
    }

    @Published var geometries = [Geometry]()
    @Published var columns = [String]()


    init(context: NSManagedObjectContext, featureCollections: [FeatureCollection]) {
        self.context = context
        self.baseGeometriesPredicate = NSPredicate(format: "feature.collection IN %@",
                                                   argumentArray: [featureCollections])
        refresh()
    }

    private func refresh() {
        let fetchRequest = NSFetchRequest<Geometry>(entityName: "Geometry")
        fetchRequest.predicate = buildPredicate()

        let gg = Self.fetchGeometries(managedObjectContext: context, request: fetchRequest)
        let features = gg.compactMap { g in
            g.feature
        }

        self.columns = features.reduce(Set<String>()) { set, f in
            return set.union(f.propertyKeys())
        }
        .sorted(using: .localizedStandard)

        self.geometries = gg
    }

    private func buildPredicate() -> NSPredicate {

        var predicates = [NSPredicate]()
        predicates.append(self.baseGeometriesPredicate)

        if self.searchText != "" {
//            let frB = NSPredicate(format: "rawShapeCode = %d", Geometry.GeoShapeType.Polygon.rawValue)
            let frB = NSPredicate(format: self.searchText)
            predicates.append(frB)
        }

        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private static func fetchGeometries(managedObjectContext: NSManagedObjectContext, request: NSFetchRequest<Geometry>) -> [Geometry] {
        do {
            return try managedObjectContext.fetch(request)
        } catch {
            fatalError()
        }
    }

    static func == (lhs: FeatureCollectionModel, rhs: FeatureCollectionModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(baseGeometriesPredicate)
        hasher.combine(context)
        hasher.combine(geometries)
        hasher.combine(searchText)
    }
}
