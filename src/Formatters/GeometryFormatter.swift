//
//  CoordinateFormatter.swift
//  Georg
//
//  Created by Michael Rockhold on 5/13/24.
//

import Foundation

class GeometryFormatter: Formatter {

    func string(from g: Geometry) -> String {
        // TODO: do this for real
        let center = g.center
        return "\(g.shape!) at lat: \(center.latitude), lng: \(center.latitude)"
    }
}
