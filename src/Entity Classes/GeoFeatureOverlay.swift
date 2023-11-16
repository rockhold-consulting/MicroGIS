//
//  GeoFeatureOverlay.swift
//  Georg
//
//  Created by Michael Rockhold on 11/15/23.
//

import Foundation
import MapKit

extension GeoFeatureOverlay: MKOverlay {
    
    public convenience init(context: NSManagedObjectContext, owner: GeoFeature, geoInfo: GeoInfoWrapper) {
        self.init(context: context)
        self.geoInfo = geoInfo
        self.owner = owner
        owner.addToOverlays(self)
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

    public var boundingMapRect: MKMapRect {
        return (self.geoInfo!.geoInfo as! MKOverlay).boundingMapRect
    }
}
