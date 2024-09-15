//
//  FeatureCollectionModel.swift
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
