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
    
    init(coordinate c: CLLocationCoordinate2D,
         boundingMapRect bmr: MKMapRect,
         polygons ps: [GeoPolygon],
         title t: String? = nil,
         subtitle st: String? = nil) {
        
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
    
    public override class var supportsSecureCoding: Bool { true }
    
    private enum CodingKeys: String, CodingKey {
        case polygons = "geomultipolygon_polygons"
    }
    
    public required init?(coder: NSCoder) {
        if let polygonArray = coder.decodeArrayOfObjects(ofClass: GeoPolygon.self,
                                                         forKey: CodingKeys.polygons.rawValue) {
            polygons = polygonArray.map { $0 } // TODO: tell me why again am I doing this
        }
        else {
            polygons = [GeoPolygon]()
        }
        super.init(coder: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(polygons, forKey: CodingKeys.polygons.rawValue)
    }
    
    public override var pinGlyph: String { return "♇♇" }

    public override func makeOverlayRenderer() -> MKOverlayRenderer {
        return MKMultiPolygonRenderer(overlay: makeMKMultiPolygon())
    }

}
