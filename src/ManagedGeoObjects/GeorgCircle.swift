//
//  GeorgCircle.swift
//  Georg
//
//  Created by Michael Rockhold on 11/8/23.
//

import Foundation
import CoreLocation
import MapKit

extension MKCircle {
    convenience init(fromGeorgObj g: GeorgCircle) {
        self.init(center: g.coordinate, radius: g.radius)
    }
}

extension GeorgCircle {
    
    public convenience init(context: NSManagedObjectContext, circle: MKCircle) {
        self.init(context: context, annotation: circle)
        self.radius = circle.radius
    }

    func makeMKCircle() -> MKCircle {
        return MKCircle(fromGeorgObj: self)
    }
}
