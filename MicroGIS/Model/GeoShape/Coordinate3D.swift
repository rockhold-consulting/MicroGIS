//
//  Coordinate3D.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 6/22/24.
//

import Foundation
import CoreLocation

public struct Coordinate3D: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double

    public init(latitude lat: Double = 0.0, longitude lng: Double = 0.0, altitude alt: Double = 0.0) {
        latitude = lat
        longitude = lng
        altitude = alt
    }

    enum CodingKeys: Int, CodingKey {
        case latitude = 101
        case longitude
        case altitude
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        altitude = try container.decode(Double.self, forKey: .altitude)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(altitude, forKey: .altitude)
    }
}

extension Geometry {
    var coordString: String {
        let coord = CLLocationCoordinate2D(latitude: coordinate.latitude,
                                           longitude: coordinate.longitude)
        return Self.coordFormatter.string(from: coord)
    }
}
