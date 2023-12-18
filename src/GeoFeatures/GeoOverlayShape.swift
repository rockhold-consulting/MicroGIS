//
//  GeoOverlayShape.swift
//  Georg
//
//  Created by Michael Rockhold on 11/14/23.
//

import Foundation
import MapKit

public class GeoOverlayShape: Geometry, MKOverlay {
    
    public let boundingMapRect: MKMapRect
    
    init(coordinate c: CLLocationCoordinate2D, boundingMapRect bmr: MKMapRect, title t: String? = nil, subtitle st: String? = nil) {
        boundingMapRect = bmr
        super.init(coordinate: c, title: t, subtitle: st)
    }

    // NSCoding/NSSecureCoding

    public override class var supportsSecureCoding: Bool { true }

    private enum CodingKeys: String, CodingKey {
        case x = "geooverlayshape_boundingmaprect_x"
        case y = "geooverlayshape_boundingmaprect_y"
        case w = "geooverlayshape_boundingmaprect_w"
        case h = "geooverlayshape_boundingmaprect_h"
    }

    public required init?(coder: NSCoder) {
        let x = coder.decodeDouble(forKey: CodingKeys.x.rawValue)
        let y = coder.decodeDouble(forKey: CodingKeys.y.rawValue)
        let w = coder.decodeDouble(forKey: CodingKeys.w.rawValue)
        let h = coder.decodeDouble(forKey: CodingKeys.h.rawValue)
        boundingMapRect = MKMapRect(x: x, y: y, width: w, height: h)
        super.init(coder: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(boundingMapRect.origin.x, forKey: CodingKeys.x.rawValue)
        coder.encode(boundingMapRect.origin.x, forKey: CodingKeys.y.rawValue)
        coder.encode(boundingMapRect.size.width, forKey: CodingKeys.w.rawValue)
        coder.encode(boundingMapRect.size.height, forKey: CodingKeys.h.rawValue)
    }
    
    public func makeOverlayRenderer() -> MKOverlayRenderer {
        return MKOverlayPathRenderer(overlay: self)
    }
}
