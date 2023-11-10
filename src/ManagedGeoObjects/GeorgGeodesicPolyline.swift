//
//  GeorgGeodesicPolyline.swift
//  Georg
//
//  Created by Michael Rockhold on 11/6/23.
//

import Foundation
import MapKit

extension MKGeodesicPolyline {
    convenience init(fromGeorgObj g: GeorgGeodesicPolyline) {
        let locationCoords = g.locationCoordinates
        self.init(coordinates: locationCoords, count: locationCoords.count)
    }
}

extension GeorgGeodesicPolyline {
    convenience init(context: NSManagedObjectContext, geodesicPolyline: MKGeodesicPolyline) {
        self.init(context: context, polyline: geodesicPolyline)
    }
    
    func makeMKGeodesicPolyline() -> MKGeodesicPolyline {
        return MKGeodesicPolyline(fromGeorgObj: self)
    }
}
