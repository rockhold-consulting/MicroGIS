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
    
    override init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, coordinates cs: [CLLocationCoordinate2D], title t: String? = nil, subtitle st: String? = nil) {
        super.init(coordinate: c, boundingMapRect: bmr, coordinates: cs, title: t, subtitle: st)
    }
    
    convenience init(polyline: MKPolyline) {
        self.init(coordinate: polyline.coordinate, boundingMapRect: polyline.boundingMapRect, coordinates: polyline.coordinates, title: polyline.title, subtitle: polyline.subtitle)
    }
    
    func makeMKPolyline() -> MKPolyline {
        return MKPolyline(fromGeoObj: self)
    }
    
    // Decodable
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
