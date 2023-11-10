//
//  GeorgMultiPolygon.swift
//  Georg
//
//  Created by Michael Rockhold on 11/6/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKMultiPolygon {
    public convenience init(fromGeorgObj g: GeorgMultiPolygon) {
        self.init(g.polygonArray().map { gPoly in MKPolygon(fromGeorgObj: gPoly) })
    }
}

extension GeorgMultiPolygon {
        
    public convenience init(context: NSManagedObjectContext, multiPolygon: MKMultiPolygon) {
        self.init(context: context, annotation: multiPolygon)
        multiPolygon.polygons.forEach { poly in
            self.addToPolygons(GeorgPolygon(context: context, polygon: poly))
        }
        self.canOverlay = true
        self.isOverlay = true
    }
    
    func makeMKMultiPolygon() -> MKMultiPolygon {
        return MKMultiPolygon(fromGeorgObj: self)
    }
    
    func polygonArray() -> [GeorgPolygon] {
        var polygons = [GeorgPolygon]()
        if let polysSet = self.polygons {
            polysSet.enumerateObjects({ obj, b in
                polygons.append(obj as! GeorgPolygon)
            })
        }
        return polygons
    }
}
