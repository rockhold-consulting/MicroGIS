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
        return "\(g.wrapped!.shape.kindString) at lat: \(g.wrapped!.baseInfo.coordinate.latitude), lng: \(g.wrapped!.baseInfo.coordinate.latitude)"
    }
}
