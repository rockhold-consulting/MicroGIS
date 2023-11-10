//
//  GeorgPolyline.swift
//  Georg
//
//  Created by Michael Rockhold on 11/6/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKPolyline {
    convenience init(fromGeorgObj g: GeorgPolyline) {
        let locationCoords = g.locationCoordinates
        self.init(coordinates: locationCoords, count: locationCoords.count)
    }
}

extension GeorgPolyline {
    
    convenience init(context: NSManagedObjectContext, polyline: MKPolyline) {
        self.init(context: context, multiPoint: polyline)
        self.canOverlay = true
        self.isOverlay = true
    }
    
    func makeMKPolyline() -> MKPolyline {
        return MKPolyline(fromGeorgObj: self)
    }
}
