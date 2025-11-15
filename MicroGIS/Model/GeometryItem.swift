//
//  GeometryItem.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 2025-01-29.
//

import Foundation
import CoreData

public struct GeometryItem: Identifiable, Hashable {
    
    static let jsonValueFormatter = JSONValueFormatter()

    public typealias ID = NSManagedObjectID
    public static func == (lhs: GeometryItem, rhs: GeometryItem) -> Bool {
        lhs.geometry.objectID == rhs.geometry.objectID
    }
    
    public let id: ID
    let geometry: Geometry
    
    init(geometry: Geometry) {
        self.id = geometry.objectID
        self.geometry = geometry
    }
    
    func propertyValue(for key: String) -> (any PropertyValue)? {
        return self.geometry.propertyValue(header: key)
    }
    
    func propertyValueString(for key: String) -> String {
        guard let value = self.propertyValue(for: key) else { return "" }
        return Self.jsonValueFormatter.string(for:  value) ?? ""
    }
}
