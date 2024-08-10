//
//  GeoObjectMKBridge.swift
//  MicroGIS
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
import BinaryCodable
import CoreData

//extension Geometry {
//    public func boundingMapRect() -> MKMapRect {
//        MKMapRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
//    }
//}

protocol Renderable where Self:Geometry {
    func makeRenderer() -> MKOverlayPathRenderer
}

extension MGPolyline: Renderable {
    func makeRenderer() -> MKOverlayPathRenderer {
        if self is MGGeodesicPolyline {
            return MKPolylineRenderer(polyline: MKGeodesicPolyline(from: self))
        } else {
            return MKPolylineRenderer(polyline: MKPolyline(from: self))
        }
    }
}

extension MGCircle: Renderable {
    @objc func makeRenderer() -> MKOverlayPathRenderer {
        return MKCircleRenderer(circle: MKCircle(center: self.center, radius: self.radius))
    }
}

extension MGPolygon: Renderable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKPolygonRenderer(polygon: MKPolygon(from: self))
    }
}

extension MGMultiPolyline: Renderable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKMultiPolylineRenderer(multiPolyline: MKMultiPolyline(from: self))
    }
}

extension MGMultiPolygon: Renderable {
    func makeRenderer() -> MKOverlayPathRenderer {
        return MKMultiPolygonRenderer(multiPolygon: MKMultiPolygon(from: self))
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

    func renderer(selected: Bool = false) -> MKOverlayRenderer? {
        return self.feature?.collection?.currentStylesheet.renderer(for: self, selected: selected)
    }
}

extension MKPolyline {
    convenience init(from polyline: MGPolyline) {
        let coords = polyline.points!.map { obj in
            (obj as! MGCoordinate).locationCoordinate2D
        }
        self.init(coordinates: coords, count: coords.count)
    }
}

extension MKGeodesicPolyline {
    convenience init(fromGeodesic polyline: MGPolyline) {
        let coords = polyline.points!.map { obj in
            (obj as! MGCoordinate).locationCoordinate2D
        }
        self.init(coordinates: coords, count: coords.count)
    }
}

extension MKPolygon {
    convenience init(from mgPolygon: MGPolygon) {
        let coords = mgPolygon.points?.map { gp in
            let point = gp as! MGCoordinate
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        }
        if mgPolygon.innerPolygons?.count == 0 {
            self.init(coordinates: coords!, count: coords!.count)
        } else {
            let innerPolygons = mgPolygon.innerPolygons?.allObjects.map { obj in
                let innerPoly = obj as! MGPolygon
                return  MKPolygon(from: innerPoly)
            }
            self.init(coordinates:coords!, count:coords!.count, interiorPolygons:innerPolygons)
        }
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
