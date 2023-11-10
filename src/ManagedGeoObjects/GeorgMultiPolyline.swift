//
//  GeorgMultiPolyline.swift
//  Georg
//
//  Created by Michael Rockhold on 11/6/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKMultiPolyline {
    convenience init(fromGeorgObj g: GeorgMultiPolyline) {
        self.init(g.polylineArray().map { gPoly in MKPolyline(fromGeorgObj: gPoly) })
    }
}

extension GeorgMultiPolyline {
    
    public convenience init(context: NSManagedObjectContext, multiPolyline: MKMultiPolyline) {
        self.init(context: context, annotation: multiPolyline)
        multiPolyline.polylines.forEach { plin in
            self.addToPolylines(GeorgPolyline(context: context, polyline: plin))
        }
        self.canOverlay = true
        self.isOverlay = true
    }
    
    func makeMKMultiPolyline() -> MKMultiPolyline {
        return MKMultiPolyline(fromGeorgObj: self)
    }
    
    func polylineArray() -> [GeorgPolyline] {
        var polylines = [GeorgPolyline]()
        if let polysSet = self.polylines {
            polysSet.enumerateObjects({ obj, b in
                polylines.append(obj as! GeorgPolyline)
            })
        }
        return polylines
    }
}
