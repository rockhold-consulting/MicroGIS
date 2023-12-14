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
