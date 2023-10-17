/*
 This file is part of GeoFeatures, a program for populating a graph of
 geo features from KML or GeoJSON files
 Copyright (C) 2023  Michael E. Rockhold

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import Foundation
import MapKit

public class Document: Element, AcceptsName, AcceptsStyle, AcceptsPlacemark {
    
    public private(set) var name: String = ""
    public private(set) var placemarks = [Placemark]()
        
    internal override func didEnd() {
        print("-Document")
        if let p = parent as? AcceptsDocument {
            p.accept(document: self)
        }
    }

    internal func accept(name: Name) {
        self.name = name.text ?? ""
    }

    internal func accept(style: Style) {
    }

    internal func accept(placemark: Placemark) {
        placemarks.append(placemark)
    }

    public var points: [Placemark] {
        return placemarks.filter { pm in
            pm.point != nil
        }
    }
    
    public var polygons: [Placemark] {
        return placemarks.filter { pm in
            pm.polygon != nil
        }
    }
}
