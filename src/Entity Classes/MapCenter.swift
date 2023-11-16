//
//  MapCenter.swift
//  Georg
//
//  Created by Michael Rockhold on 11/9/23.
//

import Foundation
import CoreLocation

extension MapCenter {
    
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
