//
//  MGCoordinate+Extension.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 8/16/24.
//

import Foundation
import CoreData
import CoreLocation

extension MGCoordinate {

    convenience init(context: NSManagedObjectContext, coordinate: CLLocationCoordinate2D) {
        self.init(context: context)
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.uniquifier = UUID()
    }

    var locationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
