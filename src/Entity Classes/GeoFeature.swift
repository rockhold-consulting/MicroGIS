//
//  GeoFeature.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreLocation
import MapKit

extension GeoFeature {
        
    convenience init(context: NSManagedObjectContext, owner: GeoLayer) {
        self.init(context: context)
        self.owner = owner
        owner.addToFeatures(self)
    }
    
}
