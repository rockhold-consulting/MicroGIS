//
//  FeatureCollectionViewModel.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 7/15/24.
//

import Foundation
import CoreData
import SwiftUI

class FeatureCollectionViewModel: Hashable, ObservableObject {
    var featureCollection: FeatureCollection
    private var context: NSManagedObjectContext
    @Published var geometries: [Geometry]
    @Published var columns: [PropertyColumn]
//    @Published var geometriesFetchRequest: NSFetchRequest<Geometry>

    init(context: NSManagedObjectContext, featureCollection: FeatureCollection) {
        self.context = context
        self.featureCollection = featureCollection

        let fr = NSFetchRequest<Geometry>(entityName: "Geometry")
//        self.geometriesFetchRequest = fr
        fr.predicate = NSPredicate(format: "feature.collection == %@", argumentArray: [featureCollection])
        let gg = Self.fetchGeometries(managedObjectContext: self.context, request: fr)

        let features = gg.compactMap { g in
            g.feature
        }

        self.columns = features.reduce(Set<String>()) { set, f in
            if let k = f.properties?.data.keys {
                return set.union(k)
            } else {
                return set
            }
        }
        .sorted(using: .localizedStandard)
        .map { PropertyColumn(str: $0) }
        self.geometries = gg
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
        hasher.combine(featureCollection)
        hasher.combine(context)
        hasher.combine(geometries)
//        hasher.combine(geometriesFetchRequest)
    }
}
