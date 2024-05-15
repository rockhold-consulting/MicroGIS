//
//  Layer+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData

extension Layer: ModelObject {
    var identifier: NSObject { self.objectID }

    var title: String? {
        get {
            self.name ?? ""
        }
        set {
            self.name = newValue
        }
    }
    
    var isLeaf: Bool { false }
    
    var kidArray: [ModelObject]? {
        var fkids = self.features?.array ?? [ModelObject]()
        fkids.append(contentsOf: self.geometries?.array ?? [])
        return fkids as? [ModelObject]
    }
    
    var icon: KitImage {
        return KitImage(systemSymbolName: "square.2.layers.3d", accessibilityDescription: "layer icon")!
    }
    
    convenience init(ctx: NSManagedObjectContext, name: String, importDate: Date) {
        self.init(context: ctx)
        self.name = name
        self.importDate = importDate
    }
}
