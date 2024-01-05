//
//  GeoOverlay.swift
//  Georg
//
//  Created by Michael Rockhold on 11/15/23.
//

import Foundation
import CoreLocation
import MapKit

@objc(GeoOverlay)
public class GeoOverlay: NSManagedObject {
    
    @objc dynamic var children: [Node]? { return nil }
    
    @objc dynamic var isLeaf: Bool { return true }
    
    var identifier: String? { return "\(objectID)" }
    
    var isSpecialGroup: Bool { return false }
    
    var icon: NSImage {
        return NSImage(systemSymbolName: "mappin.square", accessibilityDescription: "map overlay icon")!
    }
    
    var canChange: Bool { return false }
    
    var canAddTo: Bool { return false }
}

extension GeoOverlay: MKOverlay {
    
    public convenience init(context: NSManagedObjectContext, 
                            layer: GeoLayer?,
                            feature: GeoFeature?,
                            geometry: Geometry) {
        
        self.init(context: context)
        self.geometry = geometry
        self.layer = layer
        self.feature = feature
        layer?.addToOverlays(self)
        feature?.addToOverlays(self)
    }

    public var coordinate: CLLocationCoordinate2D {
        return self.geometry!.coordinate
    }
    
    public var title: String? {
        return self.geometry!.title
    }
    
    public var subtitle: String? {
        return self.geometry!.subtitle
    }

    public var boundingMapRect: MKMapRect {
        
        switch self.geometry {
        case let overlay as MKOverlay:
            return overlay.boundingMapRect
            
        case let pointAnnotation as MKPointAnnotation:
            return MKMapRect()
            
        default:
            fatalError()
        }
    }
}
