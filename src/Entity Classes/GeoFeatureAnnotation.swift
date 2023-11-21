//
//  GeoFeatureAnnotation.swift
//  Georg
//
//  Created by Michael Rockhold on 11/5/23.
//

import Foundation
import CoreLocation
import MapKit
import BinaryCodable

extension GeoFeatureAnnotation: MKAnnotation {
        
    public convenience init(context: NSManagedObjectContext, owner: GeoFeature, geoInfo: GeoObject) {
        self.init(context: context)
        self.geoInfo = geoInfo
        self.owner = owner
        owner.addToAnnotations(self)
    }
    
    public var coordinate: CLLocationCoordinate2D {
        return self.geoInfo!.coordinate
    }
    
    public var title: String? {
        return self.geoInfo!.title
    }
    
    public var subtitle: String? {
        return self.geoInfo!.subtitle
    }
}
