//
//  GeoOverlay.swift
//  Georg
//
//  Created by Michael Rockhold on 11/15/23.
//

import Foundation
import CoreLocation
import MapKit

extension GeoOverlay: MKOverlay {
    
    public convenience init(context: NSManagedObjectContext, 
                            layer: GeoLayer?,
                            feature: GeoFeature?,
                            geoInfo: GeoObject) {
        
        self.init(context: context)
        self.geoInfo = geoInfo
        self.layer = layer
        self.feature = feature
        layer?.addToOverlays(self)
        feature?.addToOverlays(self)
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
        
        switch self.geoInfo {
        case let overlay as MKOverlay:
            return overlay.boundingMapRect
            
        case let pointAnnotation as MKPointAnnotation:
            return MKMapRect()
            
        default:
            fatalError()
        }
    }
}
