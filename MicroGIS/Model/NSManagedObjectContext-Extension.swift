//
//  NSManagedObjectContext-Extension.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 1/27/25.
//

import CoreData

extension NSManagedObjectContext {
    func geometry(for id: NSManagedObjectID) -> Geometry {
        return self.object(with: id) as! Geometry
    }
}
