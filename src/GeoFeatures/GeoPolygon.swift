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
        if g.interiorPolygons.count > 0 {
            self.init(coordinates: g.coordinates,
                          count: g.coordinates.count,
                          interiorPolygons: g.interiorPolygons.map({ MKPolygon(fromGeoObj: $0) }))
        } else {
            self.init(coordinates: g.coordinates, count: g.coordinates.count)
        }
    }
}

public class GeoPolygon: GeoMultiPoint {
    
    let interiorPolygons: [GeoPolygon]
    
    public init(coordinate c: CLLocationCoordinate2D,
                         boundingMapRect bmr: MKMapRect,
                         coordinates cs: [CLLocationCoordinate2D],
                         interiorPolygons ip: [GeoPolygon],
                         title t: String? = nil,
                         subtitle st: String? = nil) {
        
        interiorPolygons = ip
        super.init(coordinate: c, boundingMapRect: bmr, coordinates: cs, title: t, subtitle: st)
    }
    
    convenience init(polygon: MKPolygon) {
        self.init(coordinate: polygon.coordinate,
                  boundingMapRect: polygon.boundingMapRect,
                  coordinates: polygon.coordinates,
                  interiorPolygons: polygon.interiorPolygons?.map({ GeoPolygon(polygon: $0) }) ?? [GeoPolygon](),
                  title: polygon.title,
                  subtitle: polygon.subtitle)
    }
    
    func makeMKPolygon() -> MKPolygon {
        return MKPolygon(fromGeoObj: self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case interiorPolygons = "geopolygon_interiorpolygons"
    }

    public override class var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let ip = coder.decodeArrayOfObjects(ofClass: GeoPolygon.self,
                                                            forKey: CodingKeys.interiorPolygons.rawValue) else {
            return nil
        }
        interiorPolygons = ip
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(interiorPolygons, forKey: CodingKeys.interiorPolygons.rawValue)
    }
    
    public override var pinGlyph: String { return "♇" }

    public override func makeOverlayRenderer() -> MKOverlayRenderer {
        return MKPolygonRenderer(overlay: makeMKPolygon())
    }

}
