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
    
    public override class var supportsSecureCoding: Bool { true }
    
    private enum CodingKeys: String, CodingKey {
        case polylines = "geomultipolyline_polylines"
    }

    public required init?(coder: NSCoder) {
        if let polylineArray = coder.decodeArrayOfObjects(ofClass: GeoPolyline.self,
                                                          forKey: CodingKeys.polylines.rawValue) {
            polylines = polylineArray.map { $0 }
        }
        else {
            polylines = [GeoPolyline]()
        }
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(polylines, forKey: CodingKeys.polylines.rawValue)
    }
}
