//
//  GeoMultiPolyline.swift
//  Georg
//
//  Created by Michael Rockhold on 11/6/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKMultiPolyline {
    convenience init(fromGeoObj g: GeoMultiPolyline) {
        self.init(g.polylines.map { MKPolyline(fromGeoObj: $0) })
    }
}

public class GeoMultiPolyline: GeoOverlayShape {
    
    let polylines: [GeoPolyline]
    
    init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, polylines ps: [GeoPolyline], title t: String? = nil, subtitle st: String? = nil) {
        polylines = ps
        super.init(coordinate: c, boundingMapRect: bmr, title: t, subtitle: st)
    }
    
    convenience init(multiPolyline: MKMultiPolyline) {
        self.init(coordinate: multiPolyline.coordinate, 
                  boundingMapRect: multiPolyline.boundingMapRect,
                  polylines: multiPolyline.polylines.map({ GeoPolyline(polyline: $0) }),
                  title: multiPolyline.title,
                  subtitle: multiPolyline.subtitle)
    }
    
    func makeMKMultiPolyline() -> MKMultiPolyline {
        return MKMultiPolyline(fromGeoObj: self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case polylines
    }

    // Decodable
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        polylines = try container.decode([GeoPolyline].self, forKey: .polylines)
        try super.init(from: container.superDecoder())
    }
    
    // Encodable
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(polylines, forKey: .polylines)
        try super.encode(to: container.superEncoder())
    }
}
