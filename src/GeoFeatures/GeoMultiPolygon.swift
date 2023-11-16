//
//  GeoMultiPolygon.swift
//  Georg
//
//  Created by Michael Rockhold on 11/6/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKMultiPolygon {
    public convenience init(fromGeoObj g: GeoMultiPolygon) {
        self.init(g.polygons.map({ MKPolygon(fromGeoObj: $0) }))
    }
}

public class GeoMultiPolygon: GeoOverlayShape {
    
    let polygons: [GeoPolygon]
    
    init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, polygons ps: [GeoPolygon], title t: String? = nil, subtitle st: String? = nil) {
        polygons = ps
        super.init(coordinate: c, boundingMapRect: bmr, title: t, subtitle: st)
    }
    
    convenience init(multiPolygon: MKMultiPolygon) {
        self.init(coordinate: multiPolygon.coordinate,
                  boundingMapRect: multiPolygon.boundingMapRect,
                  polygons: multiPolygon.polygons.map({ GeoPolygon(polygon: $0) }),
                  title: multiPolygon.title,
                  subtitle: multiPolygon.subtitle)
    }
    
    func makeMKMultiPolygon() -> MKMultiPolygon {
        return MKMultiPolygon(fromGeoObj: self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case polygons
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        polygons = try container.decode([GeoPolygon].self, forKey: .polygons)
        try super.init(from: container.superDecoder())
    }
    
    // Encodable
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(polygons, forKey: .polygons)
        try super.encode(to: container.superEncoder())
    }
}
