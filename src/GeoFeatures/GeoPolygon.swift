//
//  GeoPolygon.swift
//  Georg
//
//  Created by Michael Rockhold on 11/5/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKPolygon {
    convenience init(fromGeoObj g: GeoPolygon) {
        if let ip = g.interiorPolygons {
            if ip.count > 0 {
                self.init(coordinates: g.coordinates, count: g.coordinates.count, interiorPolygons: ip.map({ MKPolygon(coordinates: $0.coordinates, count: $0.coordinates.count) }))
            } else {
                self.init(coordinates: g.coordinates, count: g.coordinates.count)
            }
        } else {
            self.init(coordinates: g.coordinates, count: g.coordinates.count)
        }
    }
}

public class GeoPolygon: GeoMultiPoint {
    
    let interiorPolygons: [GeoPolygon]?
    
    public init(coordinate c: CLLocationCoordinate2D,
                         boundingMapRect bmr: MKMapRect,
                         coordinates cs: [CLLocationCoordinate2D],
                         interiorPolygons ip: [GeoPolygon]?,
                         title t: String? = nil,
                         subtitle st: String? = nil) {
        
        interiorPolygons = ip ?? nil
        super.init(coordinate: c, boundingMapRect: bmr, coordinates: cs, title: t, subtitle: st)
    }
    
    convenience init(polygon: MKPolygon) {
        self.init(coordinate: polygon.coordinate,
                  boundingMapRect: polygon.boundingMapRect,
                  coordinates: polygon.coordinates,
                  interiorPolygons: polygon.interiorPolygons?.map({ GeoPolygon(polygon: $0) }),
                  title: polygon.title,
                  subtitle: polygon.subtitle)
    }
    
    func makeMKPolygon() -> MKPolygon {
        return MKPolygon(fromGeoObj: self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case interiorPolygons
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        interiorPolygons = try container.decode([GeoPolygon].self, forKey: .interiorPolygons)
        try super.init(from: container.superDecoder())
    }
    
    // Encodable
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(interiorPolygons, forKey: .interiorPolygons)
        try super.encode(to: container.superEncoder())
    }
}
