//
//  FeatureCollectionViewModel.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 7/15/24.
//

import Foundation
import CoreData
import SwiftUI

class FeatureCollectionViewModel: Hashable, ObservableObject, Equatable {
    private var context: NSManagedObjectContext

    @Published var geometries: [Geometry]
    @Published var columns: [String]

    private var geometriesFetchRequest: NSFetchRequest<Geometry>

    init(context: NSManagedObjectContext, fetchRequest: NSFetchRequest<Geometry>) {
        self.context = context
        self.geometriesFetchRequest = fetchRequest

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

    convenience init(context: NSManagedObjectContext, featureCollections: [FeatureCollection]) {

        let frA = NSPredicate(format: "feature.collection IN %@",
                              argumentArray: [featureCollections])

        let frB = NSPredicate(format: "rawShapeCode = %d", Geometry.GeoShapeType.Polygon.rawValue)

        let fetchRequest = NSFetchRequest<Geometry>(entityName: "Geometry")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [frA])

        self.init(context: context, fetchRequest: fetchRequest)
    }


    private static func fetchGeometries(managedObjectContext: NSManagedObjectContext, request: NSFetchRequest<Geometry>) -> [Geometry] {
        do {
            return try managedObjectContext.fetch(request)
        } catch {
            fatalError()
        }
    }

    static func == (lhs: FeatureCollectionViewModel, rhs: FeatureCollectionViewModel) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(geometriesFetchRequest)
        hasher.combine(context)
        hasher.combine(geometries)
    }
}
