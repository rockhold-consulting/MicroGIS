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

// Cases commented out below are as-yet unsupported. They are commented out
// so that the switch statement below can have no default case, so that
// certain kinds of errors may be more conspicuous.
internal enum ElementType: String {
    case Address = "address"
//    case Color = "color"
    case Coordinates = "coordinates"
    case Description = "description"
    case Document = "document"
    case GeometryCollection = "geometrycollection"
    case InnerBoundaryIs = "innerboundaryis"
    case KML = "kml"
    case LineString = "linestring"
//    case LineStyle = "linestyle"
    case LinearRing = "linearring"
    case Name = "name"
    case OuterBoundaryIs = "outerboundaryis"
//    case Outline = "outline"
    case Placemark = "placemark"
    case Point = "point"
//    case PolyStyle = "polystyle"
    case Polygon = "polygon"
//    case Style = "style"
//    case StyleURL = "styleurl"
//    case Width = "width"
}

extension ElementType: CaseIterable {}

internal func eType(for name: String) -> ElementType? {
    let lowerName = name.lowercased()

    for e in ElementType.allCases {
        if lowerName == e.rawValue.lowercased() {
            return e
        }
    }
    return nil
}

class ElementFactory {
    public func didStartElement(name: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String], parent: Element? = nil) -> Element {
        
        if let etype = ElementType(rawValue: name.lowercased()) {
            return createElement(of: etype, attributes: attributeDict, parent: parent)
        } else {
            print("WARNING unsupported element type '\(name)' (will be ignored)")
            return Element(parent: parent, attributes: attributeDict)
        }
    }

    internal func createElement(of etype: ElementType, attributes: [String : String], parent: Element? = nil) -> Element {
        print("+\(etype)")
        
        switch etype {
        case .Address:
            return Address(parent: parent, attributes: attributes)
        case .Description:
            return Description(parent: parent, attributes: attributes)
        case .Document:
            return Document(parent: parent, attributes: attributes)
        case .GeometryCollection:
            return GeometryCollection(parent: parent, attributes: attributes)
        case .KML:
            return KMLElement(parent: parent, attributes: attributes)
        case .LineString:
            return LineString(parent: parent, attributes: attributes)
        case .Name:
            return Name(parent: parent, attributes: attributes)
        case .Placemark:
            return Placemark(parent: parent, attributes: attributes)
        case .Point:
            return Point(parent: parent, attributes: attributes)
        case .Polygon:
            return Polygon(parent: parent, attributes: attributes)
        case .Coordinates:
            return Coordinates(parent: parent, attributes: attributes)
        case .OuterBoundaryIs:
            return OuterBoundaryIs(parent: parent, attributes: attributes)
        case .InnerBoundaryIs:
            return InnerBoundaryIs(parent: parent, attributes: attributes)
        case .LinearRing:
            return LinearRing(parent: parent, attributes: attributes)
        }
    }
}
