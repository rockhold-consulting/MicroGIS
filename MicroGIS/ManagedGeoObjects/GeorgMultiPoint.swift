//
//  GeorgMultiPoint.swift
//  Georg
//
//  Created by Michael Rockhold on 11/6/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D]()
        coords.reserveCapacity(self.pointCount)
        let rng = NSRange(location: 0, length: self.pointCount)
        self.getCoordinates(&coords, range: rng)
        return coords
    }
}

extension CLLocationCoordinate2D {
    init(georgCoordinate gc: GeorgCoordinate) {
        self.init(latitude: gc.latitude, longitude: gc.longitude)
    }
}

extension GeorgMultiPoint {
    
    public convenience init(context: NSManagedObjectContext, multiPoint: MKMultiPoint) {
        self.init(context: context, annotation: multiPoint)

        for c in multiPoint.coordinates {
            self.addToCoordinates(GeorgCoordinate(context: context, coordinate: c))
        }
    }
    
    public var locationCoordinates: [CLLocationCoordinate2D] {
        get {
            let cc = self.coordinates?.allObjects ?? [CLLocationCoordinate2D]()
            return cc.map { obj in
                return CLLocationCoordinate2D(georgCoordinate: obj as! GeorgCoordinate)
            }
        }
    }
}
