//
//  File.swift
//  
//
//  Created by Michael Rockhold on 8/17/23.
//

import Foundation
import MapKit

extension Placemark {
    
    // TODO: implement for LineString, GeometryCollection, Polygon too
    var boundingMapRect: MKMapRect {
        if point != nil {
            let mp = self.mapPoint
            return MKMapRect(origin: mp, size: MKMapSize())
        } else if let polygon {
            // TODO: implement this
            return MKMapRect(x: 0, y: 0, width: 0, height: 0)
        } else {
            return MKMapRect(x: 0, y: 0, width: 0, height: 0)
        }
    }
    
    var mapPoint: MKMapPoint {
        if let pt = point {
            return MKMapPoint(pt.coordinate)
        } else {
            return MKMapPoint(x: 0, y: 0)
        }
    }
}
