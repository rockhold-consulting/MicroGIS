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

public class KMLParser: NSObject, XMLParserDelegate {
    
    private var elementStack = [Element]()
    public private(set) var kml: KMLElement? = nil
    private let elementFactory = ElementFactory() // TODO: inject this
    
    public static func parse(at url: URL) -> Document? {
        let parser = XMLParser(contentsOf: url)!
        let delegate = KMLParser()
        parser.delegate = delegate
        parser.parse()
        delegate.assignStyles()
        if let doc = delegate.kml?.document {
            return doc
        } else {
            // TODO: report problem better, or handle it better, or anyway be better than this
            return nil
        }
    }
    
    internal func assignStyles() {
        
    }
    
    public override init() {
        super.init()
    }
    
    public func parserDidStartDocument(_ parser: XMLParser) {
        elementStack = [Element]()
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
    }
    
    public func parser(_ parser: XMLParser,
                       didStartElement elementName: String,
                       namespaceURI: String?,
                       qualifiedName qName: String?,
                       attributes attributeDict: [String : String] = [:]) {
        
        if elementStack.isEmpty {
            guard elementName.lowercased() == "kml" else {
                // the only top-level element we expect is the kml, so
                // flag an error or something if we don't see 'kml' here
                // TODO: report this error better
                print("ERROR KML file is not well-formed: top-level element must be 'KML'")
                parser.abortParsing()
                return
            }
            elementStack.append(elementFactory.createElement(of: .KML, attributes: attributeDict))

        } else {
            elementStack.append(elementFactory.didStartElement(name: elementName,
                                                               namespaceURI: namespaceURI,
                                                               qualifiedName: qName,
                                                               attributes: attributeDict,
                                                               parent: elementStack.last!))
        }

//        let ident = attributeDict["id"]
//
//        let style: Style?
//        if let cpStyle = currentPlacemark?.style {
//            style = cpStyle
//        } else {
//            style = currentStyle
//        }
//
//        switch eType(for: elementName) {
//
//        // Style and sub-elements
//        case .Style:
//            if let pMark = currentPlacemark {
//                ; //pMark.beginStyle(with: ident)
//            } else {
//                ; //currentStyle = Style(identifier: ident)
//            }
//        case .PolyStyle:
//            style.beginPolyStyle()
//        case .LineStyle:
//            style.beginLineStyle()
            
//        } else if (ELTYPE(PolyStyle)) {
//            [style beginPolyStyle];
//        } else if (ELTYPE(LineStyle)) {
//            [style beginLineStyle];
//        } else if (ELTYPE(color)) {
//            [style beginColor];
//        } else if (ELTYPE(width)) {
//            [style beginWidth];
//        } else if (ELTYPE(fill)) {
//            [style beginFill];
//        } else if (ELTYPE(outline)) {
//            [style beginOutline];
//        }
//        // Placemark and sub-elements
//        else if (ELTYPE(Placemark)) {
//            self.currentPlacemark = Placemark(identifier: ident)
//        } else if (ELTYPE(Name)) {
//            [self.currentPlacemark beginName];
//        } else if (ELTYPE(Description)) {
//            [self.currentPlacemark beginDescription];
//        } else if (ELTYPE(styleUrl)) {
//            [self.currentPlacemark beginStyleUrl];
//        } else if (ELTYPE(Polygon) || ELTYPE(Point) || ELTYPE(LineString)) {
//            [self.currentPlacemark beginGeometryOfType:elementName withIdentifier:ident];
//        }
//        // Geometry sub-elements
//        else if (ELTYPE(coordinates)) {
//            [self.currentPlacemark.geometry beginCoordinates];
//        }
//        // Polygon sub-elements
//        else if (ELTYPE(outerBoundaryIs)) {
//            [self.currentPlacemark.polygon beginOuterBoundary];
//        } else if (ELTYPE(innerBoundaryIs)) {
//            [self.currentPlacemark.polygon beginInnerBoundary];
//        } else if (ELTYPE(LinearRing)) {
//            [self.currentPlacemark.polygon beginLinearRing];
//        }

    }

    public func parser(_ parser: XMLParser,
                         didEndElement elementName: String,
                         namespaceURI: String?,
                       qualifiedName qName: String?) {
        guard !elementStack.isEmpty else {
            // TODO: report error better
            print("ERROR KML file is not well-formed: parse stack is unexpectedly empty")
            parser.abortParsing()
            return
        }
        
        let topOfStack = elementStack.popLast()!
        topOfStack.didEnd()
        if elementStack.isEmpty {
            if let k = topOfStack as? KMLElement {
                kml = k
            } else {
                // TODO: report unexpected type of root object
                print("ERROR unexpected type of object at root of parse tree")
                parser.abortParsing()
            }
        }

//        let style: Style?
//        if let cpStyle = currentPlacemark?.style {
//            style = cpStyle
//        } else {
//            style = currentStyle
//        }
//
//        KMLStyle *style = [_placemark style] ? [_placemark style] : _style;
//
//        // Style and sub-elements
//        if (ELTYPE(Style)) {
//            if (_placemark) {
//                [_placemark endStyle];
//               //•• style = _style;
//            } else if (_style) {
//                [_styles setObject:_style forKey:_style.identifier];
//                [_style release];
//                _style = nil;
//            }
//        } else if (ELTYPE(PolyStyle)) {
//            [style endPolyStyle];
//        } else if (ELTYPE(LineStyle)) {
//            [style endLineStyle];
//        } else if (ELTYPE(color)) {
//            [style endColor];
//        } else if (ELTYPE(width)) {
//            [style endWidth];
//        } else if (ELTYPE(fill)) {
//            [style endFill];
//        } else if (ELTYPE(outline)) {
//            [style endOutline];
//        }
//        // Placemark and sub-elements
//        else if (ELTYPE(Placemark)) {
//            if (_placemark) {
//                [_placemarks addObject:_placemark];
//                [_placemark release];
//                _placemark = nil;
//            }
//        } else if (ELTYPE(Name)) {
//            [_placemark endName];
//        } else if (ELTYPE(Description)) {
//            [_placemark endDescription];
//        } else if (ELTYPE(styleUrl)) {
//            [_placemark endStyleUrl];
//        } else if (ELTYPE(Polygon) || ELTYPE(Point) || ELTYPE(LineString)) {
//            [_placemark endGeometry];
//        }
//        // Geometry sub-elements
//        else if (ELTYPE(coordinates)) {
//            [_placemark.geometry endCoordinates];
//        }
//        // Polygon sub-elements
//        else if (ELTYPE(outerBoundaryIs)) {
//            [_placemark.polygon endOuterBoundary];
//        } else if (ELTYPE(innerBoundaryIs)) {
//            [_placemark.polygon endInnerBoundary];
//        } else if (ELTYPE(LinearRing)) {
//            [_placemark.polygon endLinearRing];
//        }
//
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let topOfStack = elementStack.last {
            topOfStack.add(text: string)
        } else {
            print("ERROR KML file is not well-formed: parse stack is unexpectedly empty")
            parser.abortParsing()
        }
    }
    
    public func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        
        // TODO: unescape '&#nnn;' sequences more generally?
        let stringValue = String(decoding: CDATABlock, as: UTF8.self)
            .replacingOccurrences(of: "&#160;", with: " ")
            .replacingOccurrences(of: "&#169;", with: "©")
        
        if let e = elementStack.last! as? AcceptsCDATA {
            e.accept(CDATA: stringValue)
        }
    }
}
