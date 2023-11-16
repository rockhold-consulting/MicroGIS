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
        
    public convenience init(context: NSManagedObjectContext, owner: GeoFeature, geoInfo: GeoInfoWrapper) {
        self.init(context: context)
        self.geoInfo = geoInfo
        self.owner = owner
        owner.addToAnnotations(self)
    }
    
    public var coordinate: CLLocationCoordinate2D {
        return self.geoInfo?.geoInfo.coordinate ?? CLLocationCoordinate2D()
    }
    
    public var title: String? {
        return self.geoInfo?.geoInfo.title
    }
    
    public var subtitle: String? {
        return self.geoInfo?.geoInfo.subtitle
    }
}
