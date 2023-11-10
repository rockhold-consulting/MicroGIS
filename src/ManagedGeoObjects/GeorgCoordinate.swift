//
//  GeorgCoordinate.swift
//  Georg
//
//  Created by Michael Rockhold on 11/9/23.
//

import Foundation
import CoreLocation
import CoreData

extension GeorgCoordinate {

    convenience init(context ctx: NSManagedObjectContext, coordinate c: CLLocationCoordinate2D) {
        self.init(context: ctx)
        self.latitude = c.latitude
        self.longitude = c.longitude
    }

    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
}
