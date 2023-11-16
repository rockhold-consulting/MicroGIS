//
//  GeoCoordinate.swift
//  Georg
//
//  Created by Michael Rockhold on 11/9/23.
//

import Foundation
import CoreLocation
import CoreData

public class GeoCoordinate: NSObject, NSSecureCoding {

    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    init(latitude lat: CLLocationDegrees, longitude lng: CLLocationDegrees) {
        latitude = lat
        longitude = lng
    }
    
    convenience init(coordinate c: CLLocationCoordinate2D) {
        self.init(latitude: c.latitude, longitude: c.longitude)
    }

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }

    public static var supportsSecureCoding: Bool { return true }
    
    public required init?(coder: NSCoder) {
        latitude = coder.decodeDouble(forKey: CodingKeys.latitude.rawValue)
        longitude = coder.decodeDouble(forKey: CodingKeys.longitude.rawValue)
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(latitude, forKey: CodingKeys.latitude.rawValue)
        coder.encode(longitude, forKey: CodingKeys.longitude.rawValue)
    }
    
    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
    }
}
