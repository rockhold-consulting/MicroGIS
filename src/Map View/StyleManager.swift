//
//  StyleManager.swift
//  Georg
//
//  Created by Michael Rockhold on 5/11/24.
//

import Foundation
import MapKit

protocol StyleManager {
    func applyStyle(renderer: MKOverlayPathRenderer, geometry: Geometry)
}
