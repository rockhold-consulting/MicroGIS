//
//  GeoPolyline.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKPolyline {
    convenience init(fromGeoObj g: GeoPolyline) {
        self.init(coordinates: g.coordinates, count: g.coordinates.count)
    }
}

public class GeoPolyline: GeoMultiPoint {
        
    convenience init(polyline: MKPolyline) {
        self.init(coordinate: polyline.coordinate,
                  boundingMapRect: polyline.boundingMapRect,
                  coordinates: polyline.coordinates,
                  title: polyline.title,
                  subtitle: polyline.subtitle)
    }
    
    func makeMKPolyline() -> MKPolyline {
        return MKPolyline(fromGeoObj: self)
    }
    
    public override class var supportsSecureCoding: Bool { true }
}
