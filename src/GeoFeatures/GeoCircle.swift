//
//  GeoCircle.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKCircle {
    convenience init(fromGeoObj g: GeoCircle) {
        self.init(center: g.coordinate, radius: g.radius)
    }
}

public final class GeoCircle: GeoOverlayShape {
    
    let radius: CLLocationDistance
    
    init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, radius r: CLLocationDistance, title t: String? = nil, subtitle st: String? = nil) {
        radius = r
        super.init(coordinate: c, boundingMapRect: bmr, title: t, subtitle: st)
    }
    
    convenience init(circle: MKCircle) {
        self.init(coordinate: circle.coordinate, boundingMapRect: circle.boundingMapRect, radius: circle.radius, title: circle.title, subtitle: circle.subtitle)
    }

    func makeMKCircle() -> MKCircle {
        return MKCircle(fromGeoObj: self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case radius
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        radius = try container.decode(CLLocationDistance.self, forKey: .radius)
        try super.init(from: container.superDecoder())
    }
    
    // Encodable
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(radius, forKey: .radius)
        try super.encode(to: container.superEncoder())
    }
}
