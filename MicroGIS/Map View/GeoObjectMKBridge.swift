//
//  GeoObjectMKBridge.swift
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
//  Created by Michael Rockhold on 12/17/23.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS)
import UIKit
#endif
import MapKit
import CoreData

extension CLLocationCoordinate2D {
    static func bufferSize<T: SignedInteger>(for count: T) -> Int {
        return Data.Index(Int(count) * MemoryLayout<Self>.stride)
    }

    static func bufferRange<T: SignedInteger>(for count: T) -> Range<Int>  {
        return 0..<bufferSize(for: count)
    }
}

extension Geometry {

    public var center: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(self.centerLatitude), longitude: CLLocationDegrees(self.centerLongitude))
        }
        set {
            self.centerLatitude = newValue.latitude
            self.centerLongitude = newValue.longitude
        }
    }

//    func renderer(selected: Bool = false) -> MKOverlayRenderer? {
//
//        let r = makeRenderer()
//        if let ss = self.feature?.collection?.stylesheet {
//            ss.applyStyle(r, geometry: g, selected: selected)
//        }
//        return r
//    }
}

extension MKPolyline {
    convenience init(from polyline: MGPolyline) {
        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                                                           count: Int(polyline.pointCount))

        locationCoordinates.withUnsafeMutableBufferPointer { b in
            _ = polyline.pointData?.copyBytes(to: b,
                                              from: CLLocationCoordinate2D.bufferRange(for: polyline.pointCount))
        }
        self.init(coordinates: locationCoordinates,
                  count: Int(polyline.pointCount))
  }
}

//extension MKGeodesicPolyline {
//    convenience init(fromGeodesic polyline: MGPolyline) {
//        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
//                                                           count: Int(polyline.pointCount))
//
//        locationCoordinates.withUnsafeMutableBufferPointer { b in
//            _ = polyline.pointData?.copyBytes(to: b,
//                                              from: CLLocationCoordinate2D.bufferRange(for: polyline.pointCount))
//        }
//        self.init(coordinates: locationCoordinates,
//                  count: Int(polyline.pointCount))
//    }
//}

extension MKPolygon {
    convenience init(from mgPolygon: MGPolygon) {
        var locationCoordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
                                                           count: Int(mgPolygon.pointCount))

        locationCoordinates.withUnsafeMutableBufferPointer { b in
            _ = mgPolygon.pointData?.copyBytes(to: b,
                                               from: CLLocationCoordinate2D.bufferRange(for: mgPolygon.pointCount))
        }

        if mgPolygon.innerPolygons?.count == 0 {
            self.init(coordinates:locationCoordinates,
                      count:locationCoordinates.count)
        } else {
            let innerPolygons = mgPolygon.innerPolygons?.allObjects.map { obj in
                let innerPoly = obj as! MGPolygon
                return  MKPolygon(from: innerPoly)
            }
            self.init(coordinates:locationCoordinates,
                      count:locationCoordinates.count,
                      interiorPolygons:innerPolygons)
        }
    }
}

extension MKCircle {
    convenience init(from geoShape: MGCircle) {
        self.init(center: geoShape.center, radius: geoShape.radius)
    }
}

extension MKMultiPolyline {
    convenience init(from geoShape: MGMultiPolyline) {
        let polylines = ((geoShape.polylines?.allObjects) as! [MGPolyline]).map { MKPolyline(from: $0) }
        self.init(polylines)
    }
}

extension MKMultiPolygon {
    convenience init(from geoShape: MGMultiPolygon) {
        let polygons = ((geoShape.polygons?.allObjects) as! [MGPolygon]).map { MKPolygon(from: $0) }
        self.init(polygons)
    }
}

extension MKMapRect {
    static let zero: MKMapRect = MKMapRect(x:0,y:0,width:0,height:0)

    var isZero: Bool {
        MKMapRectEqualToRect(self, MKMapRect.zero)
    }

    func allUnion(_ rects: [MKMapRect]) -> MKMapRect {
        return rects.reduce(self) { partialResult, rect in
            return partialResult.union(rect)
        }
    }
}

extension MKMapView {
    func pointToMapPoint(_ point: CGPoint) -> MKMapPoint {
        return MKMapPoint(self.convert(point, toCoordinateFrom: self))
    }
}
