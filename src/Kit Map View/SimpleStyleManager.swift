//
//  SimpleStyleManager.swift
//  Georg
//
//  Created by Michael Rockhold on 5/11/24.
//

import Foundation
import MapKit

class SimpleStyleManager: StyleManager {

    func applyStyle(renderer: MKOverlayPathRenderer, geometry: Geometry) {
        switch renderer {
        case let r as MKPolylineRenderer: // handles both Polyline and GeodesicPolyline
            if geometry.wrapped?.shape is GeoGeodesicPolyline {
                r.fillColor = NSColor.blue
                r.strokeColor = NSColor.blue
                r.lineWidth = 4.0
            } else {
                r.fillColor = NSColor.green
                r.strokeColor = NSColor.green
                r.lineWidth = 4.0
            }
        case let r as MKPolygonRenderer:
            r.fillColor = NSColor.yellow
            r.strokeColor = NSColor.yellow
            r.lineWidth = 4.0
        case let r as MKMultiPolylineRenderer:
            r.fillColor = NSColor.red
            r.strokeColor = NSColor.red
            r.lineWidth = 4.0
        case let r as MKMultiPolygonRenderer:
            r.fillColor = NSColor.orange
            r.strokeColor = NSColor.orange
            r.lineWidth = 4.0
        case let r as MKCircleRenderer:
            r.fillColor = NSColor.purple
            r.strokeColor = NSColor.purple
            r.lineWidth = 4.0
        default:
            renderer.fillColor = NSColor.gray
            renderer.strokeColor = NSColor.gray
            renderer.lineWidth = 3.0
        }
    }
}
