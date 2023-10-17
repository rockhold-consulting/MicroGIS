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
import CoreLocation

public class Placemark: Element, AcceptsName, AcceptsDescription, AcceptsPoint, AcceptsLineString, AcceptsPolygon, AcceptsGeometryCollection {
    
    // Corresponds to the title property on MKAnnotation
    public private(set) var name: String? = nil
    // Corresponds to the subtitle property on MKAnnotation
    public private(set) var placemarkDescription: String? = nil
    public private(set) var address: String? = nil

    public private(set) var point: CLLocation? = nil
    public private(set) var lineString: LineString? = nil
    public private(set) var polygon: Polygon? = nil
    public private(set) var geometryCollection: GeometryCollection? = nil

    public private(set) var style: Style? = nil
    public private(set) var styleURL: URL? = nil

    private var isInteresting: Bool {
        return point != nil
        || lineString != nil
        || polygon != nil
        || geometryCollection != nil
    }
    
    internal override func didEnd() {
        print("-Placemark")
        guard isInteresting else {
            return
        }
        
        if let p = parent as? AcceptsPlacemark {
            p.accept(placemark: self)
        }
    }
    
    internal func accept(name: Name) {
        self.name = name.text
    }
    
    internal func accept(description: Description) {
        self.placemarkDescription = description.text
    }
    
    internal func accept(address: Address) {
        self.address = address.text
    }
    
    internal func accept(point: Point) {
        guard let location = point.coordinate else {
            return
        }
        
        let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        self.point = CLLocation(coordinate: coord,
                   altitude: CLLocationDistance(location.altitude),
                   horizontalAccuracy: CLLocationAccuracy(),
                   verticalAccuracy: CLLocationAccuracy(),
                   timestamp: Date())
    }

    internal func accept(lineString: LineString) {
        
    }

    internal func accept(polygon: Polygon) {
        
    }

    internal func accept(geometryCollection: GeometryCollection) {
        
    }
}
