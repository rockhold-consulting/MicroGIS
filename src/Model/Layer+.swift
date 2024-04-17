//
//  Layer+.swift
//  GeorgB
//
//  Created by Michael Rockhold on 3/21/24.
//

import Foundation
import CoreData

public extension Layer {
    convenience init(ctx: NSManagedObjectContext, name: String, importDate: Date) {
        self.init(context: ctx)
        self.name = name
        self.importDate = importDate
    }

    func add(featureChild: FeatureLike) {
        guard let child = featureChild as? Feature else {
            fatalError()
        }
        self.addToChildren(child)
        child.parent = self
    }

    func add(geometryChild: GeometryLike) {
        guard let child = geometryChild as? Geometry else {
            fatalError()
        }
        self.addToChildren(child)
        child.parent = self
    }
}

extension Layer: LayerLike {
    public func add(child: GeoObjectChild) {
        if let f = child as? Feature {
            self.addToChildren(f)
        }
        if let g = child as? Geometry {
            self.addToChildren(g)
        }
    }
}
