//
//  CLLocationCoordinate2D+Codable.swift
//  Georg
//
//  Created by Michael Rockhold on 11/14/23.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: CodingKey {
        case latitude
        case longitude
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try values.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
}

//extension CLLocationCoordinate2D {
//    public init(geoCoordinate gc: GeoCoordinate) {
//        self.init(latitude: gc.latitude, longitude: gc.longitude)
//    }
//}

