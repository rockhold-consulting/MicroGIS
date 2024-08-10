//
//  Stylesheet+Extensions.swift
//  MicroGIS
//
//  Created by Michael Rockhold on 5/11/24.
//

import Foundation
import MapKit

extension Stylesheet {
    #if os(macOS)
    typealias Kolor = NSColor
    #elseif os(iOS)
    typealias Kolor = UIColor
    #endif

    func renderer(for geometry: Geometry, selected: Bool = false) -> MKOverlayRenderer? {
        guard let r = (geometry.shape?.shape as? Rendererable)?.makeRenderer(geometry: geometry) else {
            return nil
        }
        // TODO: dummy implementation
        applyStyle(r, geometry: geometry, selected: selected)
        return r
    }

    func applyStyle(_ overlayRenderer: MKOverlayRenderer, geometry: Geometry, selected: Bool) {
        switch overlayRenderer {
        case let r as MKPolylineRenderer: // handles both Polyline and GeodesicPolyline
            if geometry.isGeodesic {
                r.fillColor = Kolor.blue
                r.strokeColor = selected ? Kolor.black : Kolor.blue
                r.lineWidth = 4.0
            } else {
                r.fillColor = Kolor.green
                r.strokeColor = selected ? Kolor.black : Kolor.green
                r.lineWidth = 4.0
            }
        case let r as MKPolygonRenderer:
            r.fillColor = selected ? Kolor.black : Kolor.yellow
            r.strokeColor = selected ? Kolor.black : Kolor.yellow
            r.lineWidth = 4.0
        case let r as MKMultiPolylineRenderer:
            r.fillColor = Kolor.red
            r.strokeColor = selected ? Kolor.black : Kolor.red
            r.lineWidth = 4.0
        case let r as MKMultiPolygonRenderer:
            r.fillColor = Kolor.orange
            r.strokeColor = selected ? Kolor.black : Kolor.orange
            r.lineWidth = 4.0
        case let r as MKCircleRenderer:
            r.fillColor = Kolor.purple
            r.strokeColor = selected ? Kolor.black : Kolor.purple
            r.lineWidth = 4.0
        case let r as MKOverlayPathRenderer:
            r.fillColor = Kolor.gray
            r.strokeColor = selected ? Kolor.black : Kolor.gray
            r.lineWidth = 3.0
        default:
            break
        }
    }
}
