//
//  GeoOverlayShape.swift
//  Georg
//
//  Created by Michael Rockhold on 11/14/23.
//

import Foundation
import MapKit

extension MKMapRect: Codable {
    private enum CodingKeys: String, CodingKey {
        case X
        case Y
        case W
        case H
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let x = try values.decode(Double.self, forKey: .X)
        let y = try values.decode(Double.self, forKey: .Y)
        let w = try values.decode(Double.self, forKey: .W)
        let h = try values.decode(Double.self, forKey: .H)
        self.init(x: x, y: y, width: w, height: h)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.origin.x, forKey: .X)
        try container.encode(self.origin.y, forKey: .Y)
        try container.encode(self.size.width, forKey: .W)
        try container.encode(self.size.height, forKey: .H)
    }
}

public class GeoOverlayShape: GeoObject {
    
    let boundingMapRect: MKMapRect
    
    init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, title t: String? = nil, subtitle st: String? = nil) {
        boundingMapRect = bmr
        super.init(coordinate: c, title: t, subtitle: st)
    }

    private enum CodingKeys: String, CodingKey {
        case boundingMapRect
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        boundingMapRect = try container.decode(MKMapRect.self, forKey: .boundingMapRect)
        try super.init(from: container.superDecoder())
    }
    
    // Encodable
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(boundingMapRect, forKey: .boundingMapRect)
        try super.encode(to: container.superEncoder())
    }

}
