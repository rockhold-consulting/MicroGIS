//
//  GeoGeodesicPolyline.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
//

import Foundation
import MapKit

extension MKGeodesicPolyline {
    convenience init(fromGeoObj g: GeoGeodesicPolyline) {
        self.init(coordinates: g.coordinates, count: g.coordinates.count)
    }
}

public class GeoGeodesicPolyline: GeoPolyline {
    
    override init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, coordinates cs: [CLLocationCoordinate2D], title t: String? = nil, subtitle st: String? = nil) {
        super.init(coordinate: c, boundingMapRect: bmr, coordinates: cs, title: t, subtitle: st)
    }

    convenience init(geodesicPolyline: MKGeodesicPolyline) {
        self.init(coordinate: geodesicPolyline.coordinate, boundingMapRect: geodesicPolyline.boundingMapRect, coordinates: geodesicPolyline.coordinates, title: geodesicPolyline.title, subtitle: geodesicPolyline.subtitle)
    }

    func makeMKGeodesicPolyline() -> MKGeodesicPolyline {
        return MKGeodesicPolyline(fromGeoObj: self)
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
