//
//  GeorgPolygon.swift
//  Georg
//
//  Created by Michael Rockhold on 11/5/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKPolygon {
    convenience init(fromGeorgObj g: GeorgPolygon) {
        var interiorPolys = [MKPolygon]()
        if let interiorPolysSet = g.interiorPolygons {
            interiorPolysSet.enumerateObjects({ obj, b in
                interiorPolys.append(MKPolygon(fromGeorgObj: obj as! GeorgPolygon))
            })
        }
        let locationCoordinates = g.locationCoordinates
        self.init(coordinates: locationCoordinates,
                  count: locationCoordinates.count,
                  interiorPolygons: interiorPolys)
    }
}

extension GeorgPolygon {
    convenience init(context: NSManagedObjectContext, polygon: MKPolygon) {
        self.init(context: context, multiPoint: polygon)
        self.canOverlay = true
        self.isOverlay = true

        if let iPolys = polygon.interiorPolygons {
            for iPoly in iPolys {
                self.addToInteriorPolygons(GeorgPolygon(context: context, polygon: iPoly))
            }
        }
    }
    
    func makeMKPolygon() -> MKPolygon {
        return MKPolygon(fromGeorgObj: self)
    }
}
