//
//  GeoFeature.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreLocation
import MapKit

typealias FeatureInfo = [String: Any]

@objc(GeoFeature)
public class GeoFeature: NSManagedObject {
    
    var info: FeatureInfo? = nil
    
    @objc dynamic var children: [GeoObject]? {
        guard let kids = self.overlays?.allObjects as? [Node] else {
            return nil
        }
        return kids.count > 1 ? kids : nil
    }
    
    @objc dynamic var isLeaf: Bool {
        guard let overlays = self.overlays else {
            return true
        }
        return overlays.count > 1
    }
    
    var title: String? { return "Feature [TODO]" }
        
    var isSpecialGroup: Bool { return false }
    
    var icon: NSImage {
        return NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "feature icon")!
    }
    
    var canChange: Bool { return false }
    
    var canAddTo: Bool { return false }
}

extension GeoFeature {
        
    convenience init(context: NSManagedObjectContext, layer: GeoLayer, geoJSONFeature: MKGeoJSONFeature) {
        self.init(context: context)
        self.layer = layer
        self.identifier = geoJSONFeature.identifier
        self.properties = geoJSONFeature.properties
        
        if let propData = self.properties, let fi = try? JSONSerialization.jsonObject(with: propData) as? FeatureInfo {
            self.info = fi
        }

        layer.addToFeatures(self)
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        if let propData = self.properties, let fi = try? JSONSerialization.jsonObject(with: propData) as? FeatureInfo {
            self.info = fi
        }
    }
    
    public override func awakeFromInsert() {
        super.awakeFromFetch()
        if let propData = self.properties, let fi = try? JSONSerialization.jsonObject(with: propData) as? FeatureInfo {
            self.info = fi
        }
    }
    
    
    public override func willTurnIntoFault() {
        info = nil
        super.willTurnIntoFault()
    }
}
