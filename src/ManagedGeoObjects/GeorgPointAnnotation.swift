//
//  GeorgPointAnnotation.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreData
import MapKit

extension GeorgPointAnnotation {
    
    convenience init(context: NSManagedObjectContext, pointAnnotation: MKPointAnnotation) {
        self.init(context: context, title: pointAnnotation.title, subtitle: pointAnnotation.subtitle)
    }
    
    convenience init(context: NSManagedObjectContext, title: String? = nil, subtitle: String? = nil) {
        self.init(context: context)
        if let t = title {
            self.title = t
        }
        if let st = subtitle {
            self.subtitle = st
        }
    }
}
