import XCTest
@testable import GeoFeatures

/*
 This file is part of GeoFeatures, a program for populating a graph of
 graphical objects from a KML or GeoJSON file
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

import XCTest
import MapKit
@testable import GeoFeatures

final class GeoFeaturesTests: XCTestCase {
    
    func testParse1() {
        // Locate the path to the fixture KML file in the test bundle
        // and parse it with the KMLParser.
        let url = Bundle.module.url(forResource: "route", withExtension: "kml")!
        let document = GeoFeatures.KMLParser.parse(at: url)
        
        XCTAssertNotNil(document)
    }
    
    func testCreatesExpectedPlacemarkPoints() throws {
        
        // Locate the path to the fixture KML file in the test bundle
        // and parse it with the KMLParser.
        let url = Bundle.module.url(forResource: "route", withExtension: "kml")!
        let document = GeoFeatures.KMLParser.parse(at: url)!
                
        // Walk the list of overlays and annotations and create a MKMapRect that
        // bounds all of them and store it into flyTo.
        var flyTo = MKMapRect.null
        for placemark in document.points {
            let pointRect = placemark.boundingMapRect
            if flyTo.isNull {
                flyTo = pointRect
            } else {
                flyTo = flyTo.union(pointRect)
            }
        }

        XCTAssertFalse(flyTo.isNull)
        XCTAssertFalse(flyTo.isEmpty)
    }

    func testCreatesExpectedPlacemarkPolygons() throws {
        
        let url = Bundle.module.url(forResource: "route", withExtension: "kml")!
        let document = GeoFeatures.KMLParser.parse(at: url)!
                
        // Walk the list of overlays and annotations and create a MKMapRect that
        // bounds all of them and store it into flyTo.
        var flyTo = MKMapRect.null
        for polygon in document.polygons {
            if flyTo.isNull {
                flyTo = polygon.boundingMapRect
            } else {
                flyTo = flyTo.union(polygon.boundingMapRect)
            }
        }
        
        XCTAssertFalse(flyTo.isNull)
        XCTAssertFalse(flyTo.isEmpty)
    }

    func testETypes() {
        XCTAssertTrue(GeoFeatures.eType(for: "LinearRing") == KMLParser.ElementType.LinearRing)
        XCTAssertNil(GeoFeatures.eType(for: "WeirdThing"))
    }
}
