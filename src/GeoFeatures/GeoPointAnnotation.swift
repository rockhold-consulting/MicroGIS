//
//  GeoPointAnnotation.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreData
import MapKit

public class GeoPointAnnotation: GeoObject {
    
//    init(coordinate c: CLLocationCoordinate2D, title t: String) {
//        super.init(coordinate: c, title: t)
//    }
    
    public override init(coordinate c: CLLocationCoordinate2D, title t: String? = nil, subtitle st: String? = nil) {
        super.init(coordinate: c, title: t, subtitle: st)
    }

    convenience init(pointAnnotation: MKPointAnnotation) {
        self.init(coordinate: pointAnnotation.coordinate, title: pointAnnotation.title, subtitle: pointAnnotation.subtitle)
    }
    
    public override class var supportsSecureCoding: Bool { true }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override var pinGlyph: String { return "⇩" }

}
