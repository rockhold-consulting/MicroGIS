//
//  GeoMultiPoint.swift
//  Georg
//
//  Created by Michael Rockhold on 11/10/23.
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

public class GeoMultiPoint: GeoOverlayShape {
    
    let coordinates: [CLLocationCoordinate2D]
    
    init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, coordinates cs: [CLLocationCoordinate2D], title t: String? = nil, subtitle st: String? = nil) {
        coordinates = cs
        super.init(coordinate: c, boundingMapRect: bmr, title: t, subtitle: st)
    }
    
    private enum CodingKeys: String, CodingKey {
        case coordinates
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        coordinates = try container.decode([CLLocationCoordinate2D].self, forKey: .coordinates)
        try super.init(from: container.superDecoder())
    }
    
    // Encodable
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinates, forKey: .coordinates)
        try super.encode(to: container.superEncoder())
    }
}
