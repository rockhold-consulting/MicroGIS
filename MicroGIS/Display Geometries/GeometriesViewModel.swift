//
//  GeometriesViewModel.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 2025-02-10.
//

import Foundation
import CoreData

public final class GeometriesViewModel: ObservableObject {
    static let maxPropertyColumns = 6
    public struct BoundingBox {
        let minLongitude: Double
        let minLatitude: Double
        let maxLongitude: Double
        let maxLatitude: Double
    }
    
    @Published public var geometryItems: [GeometryItem]
    @Published public var propertiesPresent: [String: Bool]

    init(geometryItems: [GeometryItem],
         properties: [String]
    ) {
        func allEqual<T: Equatable>(_ array: [T]) -> Bool {
            guard array.count > 1 else { return true }
            let firstElement = array[0]
            return array[1...].allSatisfy { $0 == firstElement }
        }
        
        self.geometryItems = geometryItems
        self.propertiesPresent = [String:Bool](uniqueKeysWithValues: properties.map { ($0, false)})

        for p in properties {
            let gProps = geometryItems.map { $0.propertyValueString(for: p) }
            if allEqual(gProps) {
                self.propertiesPresent[p] = true
            }
        }
    }
    
    convenience init(context: NSManagedObjectContext,
                     geometryIDs: Set<GeometryItem.ID>,
                     properties: [String]) {
        
        self.init(geometryItems: geometryIDs.compactMap {context.geometry(for: $0)}.map{ GeometryItem(geometry: $0)},
                  properties: properties)
    }
}
