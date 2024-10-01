//
//  Stylesheet+Extensions.swift
//  MicroGIS
//
//  Copyright 2024, Michael Rockhold (dba Rockhold Software)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  The license is provided with this work, or you may obtain a copy
//  of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

    // TODO: replace this dummy implementation
    func applyStyle(_ overlayRenderer: MKOverlayRenderer, geometry: Geometry, selected: Bool) {
        switch overlayRenderer {
        case let r as MKPolylineRenderer: // handles both Polyline and GeodesicPolyline
            if geometry is MGGeodesicPolyline {
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
