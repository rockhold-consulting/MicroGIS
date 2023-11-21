//
//  GeoLayerOverlay.swift
//  Georg
//
//  Created by Michael Rockhold on 11/15/23.
//

import Foundation
import MapKit

extension GeoLayerOverlay: MKOverlay {
    
    public convenience init(context: NSManagedObjectContext, owner: GeoLayer, geoInfo: GeoObject) {
        self.init(context: context)
        self.geoInfo = geoInfo
        self.owner = owner
        owner.addToOverlays(self)
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

    public var boundingMapRect: MKMapRect {
        return (self.geoInfo as? MKOverlay)!.boundingMapRect
    }

}
