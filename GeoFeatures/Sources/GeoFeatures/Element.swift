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

struct Coordinate {
    let longitude: Double
    let latitude: Double
    let altitude: Double
}

public class Element {
    let parent: Element?
    let attributes: [String : String]
    
    public var id: String? {
        return attributes["id"] ?? nil
    }
    
    public private(set) var text: String? = nil
    
    public init(parent p: Element?, attributes ad: [String : String]) {
        parent = p
        attributes = ad
    }
    
    internal func didEnd() {}

    internal func add(text t: String) {
        if text == nil {
            text = t
        } else {
            text!.append(t)
        }
    }
    
}

protocol AcceptsAddress {
    func accept(address: Address)
}
protocol AcceptsCoordinates {
    func accept(coordinates: Coordinates)
}
protocol AcceptsDescription {
    func accept(description: Description)
}
protocol AcceptsDocument {
    func accept(document: Document)
}
protocol AcceptsGeometryCollection {
    func accept(geometryCollection: GeometryCollection)
}
protocol AcceptsLineString {
    func accept(lineString: LineString)
}
protocol AcceptsName {
    func accept(name: Name)
}
protocol AcceptsPlacemark {
    func accept(placemark: Placemark)
}
protocol AcceptsPoint {
    func accept(point: Point)
}
protocol AcceptsPolygon {
    func accept(polygon: Polygon)
}
protocol AcceptsStyle {
    func accept(style: Style)
}
protocol AcceptsCDATA {
    func accept(CDATA: String)
}
