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
    
    init(coordinate c: CLLocationCoordinate2D, title t: String) {
        super.init(coordinate: c, title: t)
    }
    
    convenience init(pointAnnotation: MKPointAnnotation) {
        self.init(coordinate: pointAnnotation.coordinate, title: pointAnnotation.title!)
    }
    
    // Decodable
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
