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
    
    func makeMKGeodesicPolyline() -> MKGeodesicPolyline {
        return MKGeodesicPolyline(fromGeoObj: self)
    }

    public override class var supportsSecureCoding: Bool { true }
}
