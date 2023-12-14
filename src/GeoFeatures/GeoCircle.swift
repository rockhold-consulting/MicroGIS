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
        self.init(coordinate: circle.coordinate,
                  boundingMapRect: circle.boundingMapRect,
                  radius: circle.radius,
                  title: circle.title,
                  subtitle: circle.subtitle)
    }
    
    func makeMKCircle() -> MKCircle {
        return MKCircle(fromGeoObj: self)
    }
    
    // NSCoding/NSSecureCoding
    public override class var supportsSecureCoding: Bool { true }
    
    private enum CodingKeys: String, CodingKey {
        case radius = "geocircle_radius"
    }
    
    public required init?(coder: NSCoder) {
        radius = coder.decodeDouble(forKey: CodingKeys.radius.rawValue)
        super.init(coder: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(radius, forKey: CodingKeys.radius.rawValue)
    }

    public override var pinGlyph: String { return "◉" }

    public override func makeOverlayRenderer() -> MKOverlayRenderer {
        return MKCircleRenderer(overlay: makeMKCircle())
    }

}
